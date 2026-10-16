-- Foundation schema: roles, core tables, occurrence identity, reward invariant trigger.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

CREATE SCHEMA IF NOT EXISTS app_private;

DO $$
BEGIN
  CREATE ROLE gamecal_command_executor NOLOGIN NOINHERIT NOBYPASSRLS;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE ROLE gamecal_invariant_reader NOLOGIN NOINHERIT NOBYPASSRLS;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

GRANT USAGE ON SCHEMA public TO gamecal_command_executor, gamecal_invariant_reader;
GRANT USAGE, CREATE ON SCHEMA app_private TO gamecal_command_executor, gamecal_invariant_reader;
GRANT USAGE ON SCHEMA extensions TO gamecal_command_executor, gamecal_invariant_reader;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO gamecal_command_executor, gamecal_invariant_reader;

-- Migration runner must SET ROLE before assigning function ownership.
GRANT gamecal_command_executor TO CURRENT_USER;
GRANT gamecal_invariant_reader TO CURRENT_USER;

CREATE OR REPLACE FUNCTION app_private.derive_occurrence_id(
  definition_id uuid,
  original_scheduled_date date
)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = ''
AS $$
  SELECT extensions.uuid_generate_v5(
    'bf67d23d-270f-5606-bdb9-a90a143ad12d'::uuid,
    lower(definition_id::text) || ':' || to_char(original_scheduled_date, 'YYYY-MM-DD')
  );
$$;

CREATE OR REPLACE FUNCTION app_private.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 80),
  planning_timezone text NOT NULL CHECK (char_length(planning_timezone) BETWEEN 1 AND 64),
  reduced_motion boolean NOT NULL DEFAULT false,
  show_streaks boolean NOT NULL DEFAULT false,
  celebrations_enabled boolean NOT NULL DEFAULT true,
  temperature_unit text NOT NULL DEFAULT 'celsius'
    CHECK (temperature_unit IN ('celsius', 'fahrenheit')),
  weather_home_label text,
  weather_home_latitude double precision,
  weather_home_longitude double precision,
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  account_data_revision bigint NOT NULL DEFAULT 0 CHECK (account_data_revision >= 0),
  sync_epoch uuid NOT NULL DEFAULT gen_random_uuid(),
  deletion_requested_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_weather_coords CHECK (
    (
      weather_home_latitude IS NULL
      AND weather_home_longitude IS NULL
    )
    OR (
      weather_home_latitude BETWEEN -90 AND 90
      AND weather_home_longitude BETWEEN -180 AND 180
      AND weather_home_latitude = weather_home_latitude
      AND weather_home_longitude = weather_home_longitude
    )
  )
);

CREATE TABLE public.quest_definitions (
  id uuid NOT NULL,
  owner_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  state text NOT NULL DEFAULT 'active' CHECK (state IN ('active', 'archived')),
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id, id)
);

CREATE UNIQUE INDEX quest_definitions_id_key ON public.quest_definitions (id);

CREATE TABLE public.quest_schedule_versions (
  id uuid NOT NULL,
  owner_id uuid NOT NULL,
  definition_id uuid NOT NULL,
  effective_from date NOT NULL,
  effective_until date,
  entry_kind text NOT NULL CHECK (entry_kind IN ('quest', 'appointment')),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
  notes text NOT NULL DEFAULT '' CHECK (char_length(notes) <= 5000),
  category text NOT NULL DEFAULT 'personal'
    CHECK (category IN ('work', 'learning', 'health', 'personal', 'admin')),
  priority text NOT NULL DEFAULT 'side' CHECK (priority IN ('main', 'side')),
  blocks_time boolean NOT NULL DEFAULT false,
  anchor_date date NOT NULL,
  recurrence_kind text NOT NULL DEFAULT 'none'
    CHECK (recurrence_kind IN ('none', 'daily', 'weekly')),
  recurrence_weekdays smallint[],
  recurrence_until date,
  timing_kind text NOT NULL CHECK (timing_kind IN ('untimed', 'timed', 'all_day')),
  planning_timezone text NOT NULL CHECK (char_length(planning_timezone) BETWEEN 1 AND 64),
  start_local_time time,
  end_local_time time,
  end_local_date date,
  end_timezone text,
  start_ambiguity_choice text CHECK (start_ambiguity_choice IN ('earlier', 'later')),
  end_ambiguity_choice text CHECK (end_ambiguity_choice IN ('earlier', 'later')),
  all_day_end_exclusive date,
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id, id),
  CONSTRAINT quest_schedule_versions_owner_definition_fkey
    FOREIGN KEY (owner_id, definition_id)
    REFERENCES public.quest_definitions (owner_id, id),
  CONSTRAINT quest_schedule_versions_effective_range CHECK (
    effective_until IS NULL OR effective_until > effective_from
  )
);

CREATE UNIQUE INDEX quest_schedule_versions_id_key ON public.quest_schedule_versions (id);

CREATE TABLE public.quest_occurrences (
  id uuid NOT NULL,
  owner_id uuid NOT NULL,
  definition_id uuid NOT NULL,
  schedule_version_id uuid NOT NULL,
  original_scheduled_date date NOT NULL,
  effective_date date NOT NULL,
  entry_kind text NOT NULL CHECK (entry_kind IN ('quest', 'appointment')),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
  notes text NOT NULL DEFAULT '' CHECK (char_length(notes) <= 5000),
  category text NOT NULL CHECK (category IN ('work', 'learning', 'health', 'personal', 'admin')),
  priority text NOT NULL CHECK (priority IN ('main', 'side')),
  blocks_time boolean NOT NULL,
  timing_kind text NOT NULL CHECK (timing_kind IN ('untimed', 'timed', 'all_day')),
  start_local_time time,
  start_timezone text,
  end_local_date date,
  end_local_time time,
  end_timezone text,
  all_day_end_exclusive date,
  start_ambiguity_choice text CHECK (start_ambiguity_choice IN ('earlier', 'later')),
  end_ambiguity_choice text CHECK (end_ambiguity_choice IN ('earlier', 'later')),
  starts_at timestamptz,
  ends_at timestamptz,
  due_at timestamptz,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'skipped')),
  completed_at timestamptz,
  completion_timezone text,
  completion_local_date date,
  completion_accepted_at timestamptz,
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id, id),
  CONSTRAINT quest_occurrences_owner_definition_fkey
    FOREIGN KEY (owner_id, definition_id)
    REFERENCES public.quest_definitions (owner_id, id),
  CONSTRAINT quest_occurrences_owner_version_fkey
    FOREIGN KEY (owner_id, schedule_version_id)
    REFERENCES public.quest_schedule_versions (owner_id, id),
  CONSTRAINT quest_occurrences_definition_original_date_key
    UNIQUE (definition_id, original_scheduled_date),
  CONSTRAINT quest_occurrences_completed_fields CHECK (
    (
      status = 'completed'
      AND completed_at IS NOT NULL
      AND completion_timezone IS NOT NULL
      AND completion_local_date IS NOT NULL
      AND completion_accepted_at IS NOT NULL
    )
    OR (
      status <> 'completed'
      AND completed_at IS NULL
      AND completion_timezone IS NULL
      AND completion_local_date IS NULL
      AND completion_accepted_at IS NULL
    )
  )
);

CREATE UNIQUE INDEX quest_occurrences_id_key ON public.quest_occurrences (id);

CREATE INDEX quest_occurrences_owner_effective_date_idx
  ON public.quest_occurrences (owner_id, effective_date);

CREATE TABLE public.completion_rewards (
  id uuid NOT NULL,
  owner_id uuid NOT NULL,
  occurrence_id uuid NOT NULL,
  awarded_xp integer NOT NULL CHECK (awarded_xp > 0),
  rule_version text NOT NULL,
  awarded_at timestamptz NOT NULL DEFAULT now(),
  reversed_at timestamptz,
  reactivated_at timestamptz,
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id, id),
  CONSTRAINT completion_rewards_owner_occurrence_fkey
    FOREIGN KEY (owner_id, occurrence_id)
    REFERENCES public.quest_occurrences (owner_id, id),
  CONSTRAINT completion_rewards_occurrence_id_key UNIQUE (occurrence_id)
);

CREATE UNIQUE INDEX completion_rewards_id_key ON public.completion_rewards (id);

CREATE TABLE app_private.mutation_receipts (
  owner_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  command_name text NOT NULL,
  command_schema_version integer NOT NULL CHECK (command_schema_version > 0),
  canonical_payload_hash text NOT NULL,
  accepted_result jsonb NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_id, operation_id)
);

CREATE TRIGGER profiles_touch_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION app_private.touch_updated_at();

CREATE TRIGGER quest_definitions_touch_updated_at
BEFORE UPDATE ON public.quest_definitions
FOR EACH ROW
EXECUTE FUNCTION app_private.touch_updated_at();

CREATE TRIGGER quest_schedule_versions_touch_updated_at
BEFORE UPDATE ON public.quest_schedule_versions
FOR EACH ROW
EXECUTE FUNCTION app_private.touch_updated_at();

CREATE TRIGGER quest_occurrences_touch_updated_at
BEFORE UPDATE ON public.quest_occurrences
FOR EACH ROW
EXECUTE FUNCTION app_private.touch_updated_at();

CREATE TRIGGER completion_rewards_touch_updated_at
BEFORE UPDATE ON public.completion_rewards
FOR EACH ROW
EXECUTE FUNCTION app_private.touch_updated_at();

CREATE OR REPLACE FUNCTION app_private.check_occurrence_reward_invariant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  occ public.quest_occurrences%ROWTYPE;
  reward public.completion_rewards%ROWTYPE;
  occ_id uuid;
  occ_owner uuid;
  reward_found boolean := false;
BEGIN
  IF TG_TABLE_NAME = 'quest_occurrences' THEN
    occ_id := COALESCE(NEW.id, OLD.id);
    occ_owner := COALESCE(NEW.owner_id, OLD.owner_id);
  ELSE
    occ_id := COALESCE(NEW.occurrence_id, OLD.occurrence_id);
    occ_owner := COALESCE(NEW.owner_id, OLD.owner_id);
  END IF;

  SELECT *
  INTO occ
  FROM public.quest_occurrences o
  WHERE o.owner_id = occ_owner AND o.id = occ_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT *
  INTO reward
  FROM public.completion_rewards r
  WHERE r.owner_id = occ_owner AND r.occurrence_id = occ_id
    AND r.reversed_at IS NULL;

  reward_found := FOUND;

  IF occ.deleted_at IS NOT NULL THEN
    IF reward_found THEN
      RAISE EXCEPTION 'reward_invariant_violation' USING ERRCODE = 'P0001';
    END IF;
    RETURN NULL;
  END IF;

  IF occ.entry_kind = 'appointment' THEN
    IF reward_found THEN
      RAISE EXCEPTION 'reward_invariant_violation' USING ERRCODE = 'P0001';
    END IF;
    RETURN NULL;
  END IF;

  IF occ.status = 'completed' THEN
    IF NOT reward_found THEN
      RAISE EXCEPTION 'reward_invariant_violation' USING ERRCODE = 'P0001';
    END IF;
  ELSIF reward_found THEN
    RAISE EXCEPTION 'reward_invariant_violation' USING ERRCODE = 'P0001';
  END IF;

  RETURN NULL;
END;
$$;

ALTER FUNCTION app_private.check_occurrence_reward_invariant() OWNER TO gamecal_invariant_reader;

CREATE CONSTRAINT TRIGGER quest_occurrences_reward_invariant
AFTER INSERT OR UPDATE ON public.quest_occurrences
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION app_private.check_occurrence_reward_invariant();

CREATE CONSTRAINT TRIGGER completion_rewards_reward_invariant
AFTER INSERT OR UPDATE ON public.completion_rewards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION app_private.check_occurrence_reward_invariant();
