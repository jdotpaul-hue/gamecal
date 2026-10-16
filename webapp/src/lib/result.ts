export type Result<Value, Failure> =
  | { readonly ok: true; readonly value: Value }
  | { readonly ok: false; readonly error: Failure };

export function assertNever(_value: never): never {
  throw new Error("Unhandled application variant");
}
