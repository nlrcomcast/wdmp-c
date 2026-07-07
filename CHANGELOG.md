# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Used specific versions of external dependencies.
### Added
- Support for `rspDestination` in SET requests: parsed into `set_req_t.rspDestination` (defaults to `NULL` when absent) and echoed per parameter in the SET response only when non-NULL (`param_res_t.rspDestination`).
- Method invocation (e.g. `RDK.Operate`) over the existing SET flow: a SET-shaped request whose `value` is a Base64-encoded (`dataType` `WDMP_BASE64`) operate payload, treated as opaque and reusing the SET parse/form path with no new command type.

## [1.0.0] - 2018-06-19
### Added
- Initial stable release.

## [0.0.1] - 2016-06-29
### Added
- Initial creation

[Unreleased]: https://github.com/Comcast/wdmp-c/compare/1.0.0...HEAD
[1.0.0]: https://github.com/Comcast/wdmp-c/compare/83626ea45c4267350e3e1c11a7dbd5f28788fe09...1.0.0
