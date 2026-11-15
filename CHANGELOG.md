# Changelog

## [Unreleased]

### Fixed

- `tc` ematches (`basic match 'cmp(…)'`, `u32`, `meta`, …) failed with
  `Unable to find ematch` on any host without an iproute2 package, which is
  where the `ematch_map` table comes from. The table is now built in; a copy in
  `/etc/iproute2` or `/usr/share/iproute2` still takes precedence.

### Changed

- iproute2's test suite now runs on every native build, so a regression fails
  the build instead of shipping. Four tests the build sandbox cannot host are
  left out (`ip netns`, `bareudp`, `ip tunnel`).

## [7.0.0-1] - 2026-09-26

Initial release — `iproute2` 7.0.0 as a single self-contained binary, built
natively for Linux.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64).
- `ip`, `rtmon`, `ss`, `tc`, `bridge`, `devlink`, `rdma`, `dcb`, `vdpa`, `tipc`,
  `genl`, `dpll`, `netshaper`, `arpd`, `nstat`, `ifstat`, `rtacct` and `lnstat`
  (with `rtstat` and `ctstat`).
- Section-8 man pages embedded in the binary — read them with `unpin man iproute2 <page>`.
