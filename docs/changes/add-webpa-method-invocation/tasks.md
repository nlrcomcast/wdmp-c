## 1. Request struct + parsing

- [x] 1.1 Add `char *rspDestination;` to `set_req_t` in [src/wdmp-c.h](../../../src/wdmp-c.h) (defaults to NULL via existing `memset`).
- [x] 1.2 In `parse_set_request()` in [src/wdmp_internal.c](../../../src/wdmp_internal.c), read `rspDestination` from the request object; `strdup` into `set_req_t.rspDestination` when present and a non-NULL string, otherwise leave `NULL`.
- [x] 1.3 Free `rspDestination` in the `SET` / `SET_ATTRIBUTES` case of `wdmp_free_req_struct()` in [src/wdmp-c.c](../../../src/wdmp-c.c).

## 2. Response struct + emission

- [x] 2.1 Add `char *rspDestination;` to `param_res_t` in [src/wdmp-c.h](../../../src/wdmp-c.h).
- [x] 2.2 In `wdmp_form_set_response()` in [src/wdmp_internal.c](../../../src/wdmp_internal.c), add `rspDestination` to each response parameter object **only when** `resObj->u.paramRes->rspDestination` is non-NULL (omit the key entirely when NULL).

## 3. Validation

- [x] 3.1 Extend [tests/simple.c](../../../tests/simple.c) with a SET payload that includes `rspDestination` (e.g. `RDK.Operate`, `dataType` 5) and assert it is parsed into `set_req_t.rspDestination`.
- [x] 3.2 Add a SET payload without `rspDestination` and assert `set_req_t.rspDestination` is `NULL`.
- [x] 3.3 Add a response case asserting the `rspDestination` key is present when set and absent when NULL.
- [x] 3.4 Build and run tests under Valgrind (`make && make test`); confirm no leaks and `-Werror -Wall` clean.

## 4. Docs

- [x] 4.1 Add an entry under `[Unreleased]` in [CHANGELOG.md](../../../CHANGELOG.md) describing `rspDestination` support and method invocation over SET.

> Dependencies: 1.1 precedes 1.2/1.3; 2.1 precedes 2.2. Section 1 and Section 2 can proceed in
> parallel. Section 3 depends on Sections 1 and 2.
