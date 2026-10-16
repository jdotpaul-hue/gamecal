
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "public": {
          Tables: {
            "completion_rewards": {
                  Row: {
                    "awarded_at": string,"awarded_xp": number,"created_at": string,"id": string,"occurrence_id": string,"owner_id": string,"reactivated_at": string | null,"reversed_at": string | null,"revision": number,"rule_version": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "awarded_at"?: string,"awarded_xp": number,"created_at"?: string,"id": string,"occurrence_id": string,"owner_id": string,"reactivated_at"?: string | null,"reversed_at"?: string | null,"revision"?: number,"rule_version": string,"updated_at"?: string
                  }
                  Update: {
                    "awarded_at"?: string,"awarded_xp"?: number,"created_at"?: string,"id"?: string,"occurrence_id"?: string,"owner_id"?: string,"reactivated_at"?: string | null,"reversed_at"?: string | null,"revision"?: number,"rule_version"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "completion_rewards_owner_occurrence_fkey"
      columns: ["owner_id","occurrence_id"]
isOneToOne: false
      referencedRelation: "quest_occurrences"
      referencedColumns: ["owner_id","id"]
    }
                  ]
                },"profiles": {
                  Row: {
                    "account_data_revision": number,"celebrations_enabled": boolean,"created_at": string,"deletion_requested_at": string | null,"display_name": string,"id": string,"planning_timezone": string,"reduced_motion": boolean,"revision": number,"show_streaks": boolean,"sync_epoch": string,"temperature_unit": string,"updated_at": string,"weather_home_label": string | null,"weather_home_latitude": number | null,"weather_home_longitude": number | null
                  }
                  ComputedFields: never
                  Insert: {
                    "account_data_revision"?: number,"celebrations_enabled"?: boolean,"created_at"?: string,"deletion_requested_at"?: string | null,"display_name": string,"id": string,"planning_timezone": string,"reduced_motion"?: boolean,"revision"?: number,"show_streaks"?: boolean,"sync_epoch"?: string,"temperature_unit"?: string,"updated_at"?: string,"weather_home_label"?: string | null,"weather_home_latitude"?: number | null,"weather_home_longitude"?: number | null
                  }
                  Update: {
                    "account_data_revision"?: number,"celebrations_enabled"?: boolean,"created_at"?: string,"deletion_requested_at"?: string | null,"display_name"?: string,"id"?: string,"planning_timezone"?: string,"reduced_motion"?: boolean,"revision"?: number,"show_streaks"?: boolean,"sync_epoch"?: string,"temperature_unit"?: string,"updated_at"?: string,"weather_home_label"?: string | null,"weather_home_latitude"?: number | null,"weather_home_longitude"?: number | null
                  }
                  Relationships: [
                    
                  ]
                },"quest_definitions": {
                  Row: {
                    "archived_at": string | null,"created_at": string,"deleted_at": string | null,"id": string,"owner_id": string,"revision": number,"state": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"id": string,"owner_id": string,"revision"?: number,"state"?: string,"updated_at"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"id"?: string,"owner_id"?: string,"revision"?: number,"state"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "quest_definitions_owner_id_fkey"
      columns: ["owner_id"]
isOneToOne: false
      referencedRelation: "profiles"
      referencedColumns: ["id"]
    }
                  ]
                },"quest_occurrences": {
                  Row: {
                    "all_day_end_exclusive": string | null,"blocks_time": boolean,"category": string,"completed_at": string | null,"completion_accepted_at": string | null,"completion_local_date": string | null,"completion_timezone": string | null,"created_at": string,"definition_id": string,"deleted_at": string | null,"due_at": string | null,"effective_date": string,"end_ambiguity_choice": string | null,"end_local_date": string | null,"end_local_time": string | null,"end_timezone": string | null,"ends_at": string | null,"entry_kind": string,"id": string,"notes": string,"original_scheduled_date": string,"owner_id": string,"priority": string,"revision": number,"schedule_version_id": string,"start_ambiguity_choice": string | null,"start_local_time": string | null,"start_timezone": string | null,"starts_at": string | null,"status": string,"timing_kind": string,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "all_day_end_exclusive"?: string | null,"blocks_time": boolean,"category": string,"completed_at"?: string | null,"completion_accepted_at"?: string | null,"completion_local_date"?: string | null,"completion_timezone"?: string | null,"created_at"?: string,"definition_id": string,"deleted_at"?: string | null,"due_at"?: string | null,"effective_date": string,"end_ambiguity_choice"?: string | null,"end_local_date"?: string | null,"end_local_time"?: string | null,"end_timezone"?: string | null,"ends_at"?: string | null,"entry_kind": string,"id": string,"notes"?: string,"original_scheduled_date": string,"owner_id": string,"priority": string,"revision"?: number,"schedule_version_id": string,"start_ambiguity_choice"?: string | null,"start_local_time"?: string | null,"start_timezone"?: string | null,"starts_at"?: string | null,"status"?: string,"timing_kind": string,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "all_day_end_exclusive"?: string | null,"blocks_time"?: boolean,"category"?: string,"completed_at"?: string | null,"completion_accepted_at"?: string | null,"completion_local_date"?: string | null,"completion_timezone"?: string | null,"created_at"?: string,"definition_id"?: string,"deleted_at"?: string | null,"due_at"?: string | null,"effective_date"?: string,"end_ambiguity_choice"?: string | null,"end_local_date"?: string | null,"end_local_time"?: string | null,"end_timezone"?: string | null,"ends_at"?: string | null,"entry_kind"?: string,"id"?: string,"notes"?: string,"original_scheduled_date"?: string,"owner_id"?: string,"priority"?: string,"revision"?: number,"schedule_version_id"?: string,"start_ambiguity_choice"?: string | null,"start_local_time"?: string | null,"start_timezone"?: string | null,"starts_at"?: string | null,"status"?: string,"timing_kind"?: string,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "quest_occurrences_owner_definition_fkey"
      columns: ["owner_id","definition_id"]
isOneToOne: false
      referencedRelation: "quest_definitions"
      referencedColumns: ["owner_id","id"]
    },{
      foreignKeyName: "quest_occurrences_owner_version_fkey"
      columns: ["owner_id","schedule_version_id"]
isOneToOne: false
      referencedRelation: "quest_schedule_versions"
      referencedColumns: ["owner_id","id"]
    }
                  ]
                },"quest_schedule_versions": {
                  Row: {
                    "all_day_end_exclusive": string | null,"anchor_date": string,"blocks_time": boolean,"category": string,"created_at": string,"definition_id": string,"deleted_at": string | null,"effective_from": string,"effective_until": string | null,"end_ambiguity_choice": string | null,"end_local_date": string | null,"end_local_time": string | null,"end_timezone": string | null,"entry_kind": string,"id": string,"notes": string,"owner_id": string,"planning_timezone": string,"priority": string,"recurrence_kind": string,"recurrence_until": string | null,"recurrence_weekdays": (number)[] | null,"revision": number,"start_ambiguity_choice": string | null,"start_local_time": string | null,"timing_kind": string,"title": string,"updated_at": string
                  }
                  ComputedFields: never
                  Insert: {
                    "all_day_end_exclusive"?: string | null,"anchor_date": string,"blocks_time"?: boolean,"category"?: string,"created_at"?: string,"definition_id": string,"deleted_at"?: string | null,"effective_from": string,"effective_until"?: string | null,"end_ambiguity_choice"?: string | null,"end_local_date"?: string | null,"end_local_time"?: string | null,"end_timezone"?: string | null,"entry_kind": string,"id": string,"notes"?: string,"owner_id": string,"planning_timezone": string,"priority"?: string,"recurrence_kind"?: string,"recurrence_until"?: string | null,"recurrence_weekdays"?: (number)[] | null,"revision"?: number,"start_ambiguity_choice"?: string | null,"start_local_time"?: string | null,"timing_kind": string,"title": string,"updated_at"?: string
                  }
                  Update: {
                    "all_day_end_exclusive"?: string | null,"anchor_date"?: string,"blocks_time"?: boolean,"category"?: string,"created_at"?: string,"definition_id"?: string,"deleted_at"?: string | null,"effective_from"?: string,"effective_until"?: string | null,"end_ambiguity_choice"?: string | null,"end_local_date"?: string | null,"end_local_time"?: string | null,"end_timezone"?: string | null,"entry_kind"?: string,"id"?: string,"notes"?: string,"owner_id"?: string,"planning_timezone"?: string,"priority"?: string,"recurrence_kind"?: string,"recurrence_until"?: string | null,"recurrence_weekdays"?: (number)[] | null,"revision"?: number,"start_ambiguity_choice"?: string | null,"start_local_time"?: string | null,"timing_kind"?: string,"title"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "quest_schedule_versions_owner_definition_fkey"
      columns: ["owner_id","definition_id"]
isOneToOne: false
      referencedRelation: "quest_definitions"
      referencedColumns: ["owner_id","id"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "complete_occurrence":
{ Args: { "request": Json }; Returns: Json
                           },
"create_quest":
{ Args: { "request": Json }; Returns: Json
                           },
"ensure_profile":
{ Args: { "request": Json }; Returns: Json
                           },
"get_calendar_scope":
{ Args: { "request": Json }; Returns: Json
                           },
"get_own_operation_result":
{ Args: { "request": Json }; Returns: Json
                           },
"get_profile":
{ Args: { "request": Json }; Returns: Json
                           },
"get_progression":
{ Args: { "request": Json }; Returns: Json
                           },
"skip_occurrence":
{ Args: { "request": Json }; Returns: Json
                           },
"undo_occurrence":
{ Args: { "request": Json }; Returns: Json
                           },
"unskip_occurrence":
{ Args: { "request": Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "public": {
          Enums: {
            
          }
        }
} as const
