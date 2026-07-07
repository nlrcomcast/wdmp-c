# Project Context

## Purpose
`wdmp-c` is a C implementation of the **WebPA Data Model Parser**. It is part of the
[xmidt-org](https://github.com/xmidt-org) / Comcast WebPA ecosystem and provides a
lightweight library that:

- Parses incoming WebPA request JSON payloads (e.g. `GET`, `SET`, `TEST_AND_SET`,
  `REPLACE_ROWS`, `ADD_ROW`, `DELETE_ROW`) into strongly-typed C structures (`req_struct`).
- Serializes response C structures (`res_struct`) back into JSON payloads.
- Maps WebPA data-model operations against TR-181 / SNMP style parameter namespaces
  (e.g. `Device.DeviceInfo.Webpa.Enable`).
- Provides helpers to translate internal `WDMP_STATUS` codes into human-readable status
  messages and HTTP-like response status codes.

The library is intended to be embedded in device firmware / gateway components that need
to interpret and respond to WebPA data-model commands.

## Tech Stack
- **Language:** C (C99 — `-std=c99`, `-D_GNU_SOURCE`)
- **Build System:** CMake (`cmake_minimum_required(VERSION 2.8.7)`), CTest for test orchestration
- **Testing Framework:** CUnit (`CUnit/Basic.h`)
- **Code Coverage:** gcov / `-fprofile-arcs -ftest-coverage` (reported via Codecov)
- **Static Analysis:** Coverity Scan
- **CI:** GitHub Actions (`CI` workflow)
- **External Dependencies (fetched at build time via CMake `ExternalProject_Add`):**
  - [cJSON](https://github.com/DaveGamble/cJSON) — JSON parsing/serialization (pinned tag `39853e5148dad8dc5d32ea2b00943cf4a0c6f120`)
  - [cimplog](https://github.com/Comcast/cimplog) — logging abstraction (pinned tag `8a5fb3c2f182241d17f5342bea5b7688c28cd1fd`)
- **Linked system libraries (tests):** `gcov`, `cunit`, `cjson`, `m`, `cimplog`, `rt`

## Project Conventions

### Code Style
- **C99** with strict compilation: `-Werror -Wall` (warnings are treated as errors).
- **License header:** Every source, header, and CMake file begins with the Apache License 2.0
  header block and the Comcast copyright notice.
- **File section banners:** `.c` / `.h` files use consistent comment banners to organize code:
  ```
  /*----------------------------------------------------------------------------*/
  /*                                   Macros                                    */
  /*----------------------------------------------------------------------------*/
  ```
  Common sections: `Macros`, `Data Structures`, `File Scoped Variables`,
  `Function Prototypes`, `External Functions`, `Internal functions`. Empty sections are
  explicitly marked `/* none */`.
- **Naming conventions:**
  - Enums / constants: `UPPER_SNAKE_CASE` (e.g. `WDMP_STRING`, `WDMP_ERR_TIMEOUT`, `WDMP_SUCCESS`).
  - Public API functions: `wdmp_` prefix + `lower_snake_case` (e.g. `wdmp_parse_request`, `wdmp_form_response`, `wdmp_free_req_struct`).
  - `typedef` structs: `lower_snake_case` with a `_t` suffix or `_struct`/`_req_t`/`_res_t` convention (e.g. `param_t`, `get_req_t`, `req_struct`, `res_struct`).
  - Struct fields: `camelCase` (e.g. `paramNames`, `paramCnt`, `reqType`, `newCid`).
  - Logging macros: `Wdmp` prefix (`WdmpError`, `WdmpInfo`, `WdmpPrint`).
- **Indentation:** 4 spaces (note: some legacy blocks mix tabs — new code should prefer 4-space indentation).
- **Memory ownership:** The library allocates output structures (`req_struct`, `res_struct`);
  callers **must** free them via the provided `wdmp_free_req_struct()` / `wdmp_free_res_struct()`
  functions rather than freeing directly. This contract is documented in the header doc-comments.
- **Documentation:** Public API functions are documented with Doxygen-style `@param` / `@note` comment blocks in `wdmp-c.h`.

### Architecture Patterns
- **Static + shared library:** `src/CMakeLists.txt` builds both a static (`wdmp-c`) and a
  shared (`wdmp-c.shared` → output name `wdmp-c`) library from the same sources.
- **Public / internal header split:**
  - `src/wdmp-c.h` — public API, data types, enums, and documented function prototypes.
  - `src/wdmp_internal.h` — internal parse/form helper prototypes, response status codes, and logging macros (not part of the stable public surface).
- **Command dispatch pattern:** `wdmp_parse_generic_request()` parses the JSON `command`
  field and dispatches to a dedicated `parse_*_request()` handler per command type. Response
  formation mirrors this with `wdmp_form_*_response()` handlers.
- **Tagged union request/response model:** `req_struct` and `res_struct` use a `REQ_TYPE`
  discriminator plus a `union` (`getReq`/`setReq`/`tableReq`/`testSetReq`) to represent the
  active command variant.
- **Compile-time platform switch:** `DEVICE_EXTENDER` macro toggles the logging backend —
  when defined, logging falls back to `printf` and the `cimplog` dependency is excluded;
  otherwise `cimplog_*` functions are used.
- **Dependency vendoring at build time:** External dependencies are pinned to specific git
  SHAs and pulled/built via CMake `ExternalProject_Add` (skipped when `BUILD_YOCTO` is set,
  so Yocto layers can supply their own).

### Testing Strategy
- **Framework:** CUnit-based unit tests located in `tests/` (`tests/simple.c`).
- **Runner:** Registered with CTest via `add_test(NAME Simple COMMAND ... ./simple)` and
  gated behind the `BUILD_TESTING` option.
- **Approach:** Tests exercise the parser with representative JSON payloads and assert on
  the resulting struct fields (request type, parameter counts, parameter names/values),
  including negative cases (e.g. `NULL` payloads must yield a `NULL` request object).
- **Coverage:** Test builds compile with `-fprofile-arcs -ftest-coverage -O0` and link `gcov`;
  coverage is published to Codecov.
- **Memory checking:** Tests are run under Valgrind (`valgrind --leak-check=full
  --show-reachable=yes -v`) by default, controllable via the `DISABLE_VALGRIND` option —
  reflecting an emphasis on leak-free code given manual memory management.

> Note: `CONTRIBUTING.md` references Go (`golang`) testing tooling and formatting, which
> appears to be copied from a sibling project template and does **not** match this C
> codebase. The authoritative testing approach for this repo is CUnit + CTest + Valgrind.

### Git Workflow
- **Contribution model:** Fork-and-pull-request via GitHub (documented in `CONTRIBUTING.md`).
- **CLA required:** Contributors must sign the Comcast Contributor License Agreement (CLA)
  before merge.
- **Pull request guidelines:**
  - Narrowly focused, no more than 3–4 logical commits.
  - Address no more than one issue where possible.
  - Reviewable in the GitHub code review tool.
  - Linked to related issues (issue number after `#` in commit/PR messages).
- **Versioning:** [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
- **Changelog:** Maintained in `CHANGELOG.md` following the
  [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format, with an `[Unreleased]`
  section and version-comparison links.
- **Branching:** [Not clearly defined in repository] — the default/mainline branch referenced in badges is `master`.

## Domain Context
- **WebPA:** A protocol/mechanism used to remotely manage devices (gateways, CPE) over the
  Comcast/xmidt infrastructure. WebPA carries data-model commands as JSON payloads.
- **WDMP:** WebPA Data Model Parser — the concern of this library: translating between JSON
  wire payloads and typed C structures.
- **TR-181:** A device data-model standard; parameter names follow dotted paths such as
  `Device.DeviceInfo.Webpa.Enable` or `Device.WiFi.SSID.1.SSID`. `WDMP_TR181` is the primary
  `PAYLOAD_TYPE`; `WDMP_SNMP` is also recognized.
- **CID / CMC:** `TEST_AND_SET` operations use synchronization parameters
  `X_COMCAST-COM_CID` (Config ID) and `X_COMCAST-COM_CMC` (Config Mask/Change) —
  see `WDMP_SYNC_PARAM_CID` / `WDMP_SYNC_PARAM_CMC`. Related status codes include
  `WDMP_STATUS_CID_TEST_FAILED` (550) and `WDMP_STATUS_CMC_TEST_FAILED` (551).
- **Data types:** Parameter values are typed via `DATA_TYPE` (e.g. `WDMP_STRING`, `WDMP_INT`,
  `WDMP_UINT`, `WDMP_BOOLEAN`, `WDMP_BASE64`, `WDMP_BLOB`, etc.).
- **Response status codes:** Internal `WDMP_RESPONSE_STATUS_CODE` values mirror HTTP-like
  semantics (e.g. `200` success, `201` add-row success, `202` request in progress,
  `520`/`530`/`550`/`551`/`552` failure variants).
- **Table operations:** Row-based data-model tables are handled via `table_req_t` /
  `TableData` for `REPLACE_ROWS`, `ADD_ROW`, and `DELETE_ROW`.

## Important Constraints
- **Manual memory management:** No garbage collection — allocations returned by the library
  must be freed with the dedicated free functions, and code is expected to be Valgrind-clean.
- **Strict compilation:** `-Werror -Wall` means any warning breaks the build.
- **C99 standard** must be maintained.
- **Bounded parameter arrays:** `get_req_t.paramNames` is a fixed-size array of `512`
  entries; `MAX_PARAMETER_LEN` is `512` and `MAX_RESULT_LEN` is `128` — parsers must respect
  these limits.
- **Platform portability:** Must build both with `cimplog` (default) and in a `printf`-only
  mode for `DEVICE_EXTENDER` targets, and support Yocto builds via `BUILD_YOCTO`.
- **Licensing:** Apache License 2.0; all files must carry the standard Comcast Apache header.
- **Pinned dependency versions:** External dependencies are locked to specific git SHAs for
  reproducible builds (see `CHANGELOG.md` `[Unreleased]` — "Used specific versions of external dependencies").

## External Dependencies
- **cJSON** — `https://github.com/DaveGamble/cJSON` (JSON parse/serialize). Pinned tag `39853e5148dad8dc5d32ea2b00943cf4a0c6f120`.
- **cimplog** — `https://github.com/Comcast/cimplog` (logging). Pinned tag `8a5fb3c2f182241d17f5342bea5b7688c28cd1fd`. Excluded when `DEVICE_EXTENDER` is defined.
- **CUnit** — unit testing framework (expected to be available on the system / `/usr/include`).
- **Valgrind** — runtime memory-leak analysis for tests.
- **System libraries:** `libm`, `librt`, `gcov`.
- **CI / quality services:** GitHub Actions (build), Codecov (coverage), Coverity Scan (static analysis).

## Additional Notes
- **Repository layout:**
  - `src/` — library sources (`wdmp-c.c`, `wdmp-c.h`, `wdmp_internal.c`, `wdmp_internal.h`) and its `CMakeLists.txt`.
  - `tests/` — CUnit tests (`simple.c`) and its `CMakeLists.txt`.
  - Root — top-level `CMakeLists.txt`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `LICENSE`, `NOTICE`.
- **Build & test quickstart** (from `README.md`):
  ```
  mkdir build
  cd build
  cmake ..
  make
  make test
  ```
- **Workspace scope:** The current workspace contains a **single repository** (`wdmp-c`).
  No additional sibling repositories were found under the workspace root, so all analysis
  above pertains to `wdmp-c`.
- **Public API surface** (from `src/wdmp-c.h`):
  - `wdmp_parse_request(char *payload, req_struct **reqObj)`
  - `wdmp_parse_generic_request(char *payload, PAYLOAD_TYPE payload_type, req_struct **reqObj)`
  - `wdmp_form_response(res_struct *resObj, char **payload)`
  - `wdmp_free_req_struct(req_struct *reqObj)`
  - `wdmp_free_res_struct(res_struct *resObj)`
  - `mapWdmpStatusToStatusMessage(WDMP_STATUS status, char *result)`
- **Documentation inconsistency to be aware of:** `CONTRIBUTING.md` mentions Go tooling and
  "idiomatic golang code formatting," which is inconsistent with this C project and should be
  disregarded for this repository (likely inherited from a shared org template).
