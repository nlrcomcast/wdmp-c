## ADDED Requirements

### Requirement: SET Response rspDestination Emission

The SET response former SHALL carry `rspDestination` on the response parameter model
(`param_res_t.rspDestination`) and SHALL emit the `rspDestination` key in the SET response
JSON **only when** it is non-NULL. When `rspDestination` is `NULL`, the response former SHALL
omit the key entirely, leaving existing SET response output unchanged.

#### Scenario: rspDestination emitted when set

- **WHEN** a SET response has `param_res_t.rspDestination` set to `event:some-dest/thing`
- **THEN** the response JSON SHALL include `"rspDestination": "event:some-dest/thing"`

#### Scenario: rspDestination omitted when NULL

- **WHEN** a SET response has `param_res_t.rspDestination` equal to `NULL`
- **THEN** the response JSON SHALL NOT contain an `rspDestination` key
