## ADDED Requirements

### Requirement: Method Invocation Over SET Flow

WebPA SHALL support method invocation requests delivered over the existing `PATCH`/SET flow.
A method invocation SHALL be expressed as a SET-shaped request whose parameter `name`
identifies the method (e.g. `RDK.Operate`), whose `value` contains the Base64-encoded UTF-8
JSON operate payload, and whose `dataType` is `WDMP_BASE64` (`5`). The library SHALL parse
such requests using the existing SET parser without introducing a new command type or
dispatch path. The library SHALL NOT decode, validate, or interpret the operate `value`; it
SHALL treat it as an opaque string.

#### Scenario: Method request parsed as SET

- **WHEN** a `PATCH` payload contains a parameter `{ "name": "RDK.Operate", "value": "<base64>", "dataType": 5 }`
- **THEN** the library SHALL parse it via the SET flow with `reqType` = `SET` and the parameter's `type` = `WDMP_BASE64`

#### Scenario: Operate value treated as opaque

- **WHEN** a method request's `value` holds a Base64-encoded operate payload
- **THEN** the library SHALL store the `value` string verbatim without decoding or validating it

#### Scenario: Method request with rspDestination

- **WHEN** a method request includes `rspDestination` set to `event:some-dest/thing`
- **THEN** `set_req_t.rspDestination` SHALL be populated with `event:some-dest/thing`
  (see `specs/set-request/spec.md`)
