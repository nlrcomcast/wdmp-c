## Context

WDMP SET requests arrive as JSON with a `parameters` array; each entry has `name`, `value`,
and `dataType`. Method invocation (e.g. `RDK.Operate`) reuses this exact SET shape: the
`value` is a Base64-encoded (`dataType` = 5) operate payload and an optional `rspDestination`
names an asynchronous result sink (e.g. `event:some-dest/thing`).

The parser (`parse_set_request()` in `src/wdmp_internal.c`) currently reads only `name`,
`value`, and `dataType`, discarding `rspDestination`. The SET response
(`wdmp_form_set_response()`) emits only `name` + `message` per parameter and a top-level
`statusCode`. The request/response models are the shared structs `set_req_t` and
`param_res_t` in `src/wdmp-c.h`.

Constraints: C99, `-Werror -Wall`, manual memory management (must stay Valgrind-clean), and
the `param_t` type is shared across GET/SET/TEST_AND_SET, so it should not be widened for a
SET-only concern.

## Goals / Non-Goals

- Goals:
  - Preserve `rspDestination` from SET request JSON into `set_req_t`.
  - Echo `rspDestination` in the SET response JSON only when it is non-NULL.
  - Support method invocation with **no** new command type or dispatch branch.
- Non-Goals:
  - Interpreting, validating, or Base64-decoding the operate `value`.
  - Adding a distinct `REQ_TYPE` (e.g. `OPERATE`) or new parse/form handlers.
  - Changing GET / TEST_AND_SET / table request or response shapes.

## Decisions

- **Decision: Store `rspDestination` at the request level on `set_req_t`, not on `param_t`.**
  Method requests carry a single destination for the operation, and `param_t` is reused by
  GET/SET/TEST_AND_SET response paths; widening it would ripple into unrelated code. A single
  `char *rspDestination` on `set_req_t` keeps the concern SET-scoped and defaults cleanly to
  `NULL` via the existing `memset` of the struct.
- **Decision: Add `char *rspDestination` to `param_res_t` and emit it per response parameter
  only when non-NULL.** This mirrors how method callers expect the destination echoed back
  without polluting responses for ordinary SETs (the key is omitted entirely when `NULL`).
- **Decision: Reuse the SET flow for method invocation.** The request is identified by its
  parameter `name` (e.g. `RDK.Operate`) and `dataType` = `WDMP_BASE64`; no dispatch changes
  are needed, minimizing surface area and risk.
- Alternatives considered:
  - *Per-parameter `rspDestination` on `param_t`*: most faithful to the JSON layout but
    over-broad; rejected to avoid touching shared GET/TEST_AND_SET code.
  - *New `OPERATE` command type + handlers*: clearer semantically but duplicates the SET
    parse/form logic and expands the public enum; rejected as unnecessary complexity.

## Risks / Trade-offs

- Adding trailing fields to `set_req_t` / `param_res_t` changes struct layout → could affect
  ABI for consumers compiled against the old headers. Mitigation: fields are appended at the
  end and default to `NULL`; document under `[Unreleased]` and follow SemVer (minor bump).
- Forgetting to free `rspDestination` would introduce a leak. Mitigation: extend the
  `SET` / `SET_ATTRIBUTES` case in `wdmp_free_req_struct()` and add Valgrind-covered tests.

## Migration Plan

No migration required for existing payloads. Callers wanting the feature recompile against
the updated headers; `rspDestination` is optional and NULL-safe everywhere. Rollback is a
straightforward revert of the header/parser/response/free changes.

## Open Questions

- None. Placement (request-level on `set_req_t`) and response behavior (emit only when
  non-NULL, added to `param_res_t`) were confirmed with the requester.
