## ADDED Requirements

### Requirement: SET Request rspDestination Parsing

The SET request parser SHALL read an optional `rspDestination` field from the request JSON and
store it in the SET request struct (`set_req_t.rspDestination`). When `rspDestination` is
absent or not a valid string, the parser SHALL default `set_req_t.rspDestination` to `NULL`.
The parsed `rspDestination` SHALL be released by `wdmp_free_req_struct()` so the library
remains leak-free.

#### Scenario: rspDestination present in SET request

- **WHEN** a SET payload contains a parameter with `rspDestination` set to `event:some-dest/thing`
- **THEN** the parser SHALL populate `set_req_t.rspDestination` with `event:some-dest/thing`

#### Scenario: rspDestination absent in SET request

- **WHEN** a SET payload contains no `rspDestination` field
- **THEN** `set_req_t.rspDestination` SHALL be `NULL`

#### Scenario: Parsed rspDestination is freed

- **WHEN** a SET request with a non-NULL `rspDestination` is released via `wdmp_free_req_struct()`
- **THEN** the memory for `rspDestination` SHALL be freed with no leak reported by Valgrind
