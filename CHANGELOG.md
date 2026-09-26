# Changelog

## [Unreleased]

## [7.0.0-1] - 2026-09-26

Initial release — `iproute2` 7.0.0 as a single self-contained binary, built
natively for Linux.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64).
- `ip`, `rtmon`, `ss`, `tc`, `bridge`, `devlink`, `rdma`, `dcb`, `vdpa`, `tipc`,
  `genl`, `dpll`, `netshaper`, `arpd`, `nstat`, `ifstat`, `rtacct` and `lnstat`
  (with `rtstat` and `ctstat`).
- Section-8 man pages embedded in the binary — read them with `unpin man iproute2 <page>`.
