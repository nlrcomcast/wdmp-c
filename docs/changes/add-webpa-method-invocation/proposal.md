## Why

WebPA needs to support **method invocation** requests (e.g. `RDK.Operate`) that are
delivered over the existing `PATCH`/SET flow. A method invocation carries a Base64-encoded
(`dataType` = 5) JSON operate payload and, optionally, an asynchronous result destination
(`rspDestination`). Today the WDMP SET parser drops `rspDestination`, so the destination for
the operation result cannot be propagated to Parodus2ccsp, and the SET response cannot echo it.

## What Changes

- Parse `rspDestination` from the SET request JSON and store it in the SET request struct
  (`set_req_t.rspDestination`). When absent, it defaults to `NULL`.
- Emit `rspDestination` in the SET response JSON, per parameter, **only when it is non-NULL**
  (added to `param_res_t`).
- Document that a method invocation is a SET-shaped request identified by its parameter
  `name` (e.g. `RDK.Operate`) whose `value` is a Base64-encoded operate payload with
  `dataType` = `WDMP_BASE64` (5). No new command type or dispatch path is introduced — method
  requests reuse the existing SET parse/form flow.
- Free `set_req_t.rspDestination` in `wdmp_free_req_struct()` for the `SET` / `SET_ATTRIBUTES`
  paths to keep the library Valgrind-clean.

No breaking changes: `set_req_t` and `param_res_t` gain new trailing fields that default to
`NULL`; existing callers and payloads that do not use `rspDestination` are unaffected.

## Impact

- Affected specs:
  - `set-request` (ADDED: `rspDestination` parsing)
  - `set-response` (ADDED: conditional `rspDestination` emission)
  - `method-invocation` (ADDED: new capability describing method requests over SET)
- Affected code:
  - `src/wdmp-c.h` — add `rspDestination` to `set_req_t` and `param_res_t`.
  - `src/wdmp_internal.c` — `parse_set_request()` parse `rspDestination`;
    `wdmp_form_set_response()` emit `rspDestination` when non-NULL.
  - `src/wdmp-c.c` — `wdmp_free_req_struct()` free `rspDestination` for SET.
  - `tests/simple.c` — add coverage for present/absent `rspDestination`.
  - `CHANGELOG.md` — note under `[Unreleased]`.
