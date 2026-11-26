# iproute2

[iproute2](https://wiki.linuxfoundation.org/networking/iproute2) — the Linux networking programs: `ip` (addresses, links, routes, rules, neighbours, namespaces, tunnels), `ss` (sockets), `tc` (traffic control), `bridge`, `devlink`, `rdma`, `dcb`, `vdpa`, `tipc`, `dpll`, `netshaper` and the `nstat`/`ifstat`/`lnstat`/`rtacct` counters. A single self-contained binary, built natively for Linux.

[![CI](https://github.com/unpins/iproute2/actions/workflows/iproute2.yml/badge.svg)](https://github.com/unpins/iproute2/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install iproute2`.

Linux-only: iproute2 talks to the Linux kernel over netlink, which macOS and Windows do not have.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin iproute2 --unpin-program=ip -br addr        # addresses, one line per interface
unpin iproute2 --unpin-program=ip route           # routing table
unpin iproute2 --unpin-program=ss -tlnp           # listening TCP sockets and their processes
unpin iproute2 --unpin-program=tc qdisc show      # queueing disciplines
```

To install the programs onto your PATH:

```bash
unpin install iproute2
```

`unpin install iproute2` creates `ip`, `ss`, `tc`, `bridge` and the rest (plus the `rtstat` and `ctstat` aliases of `lnstat`). `unpin info iproute2` lists every command.

## Man pages

The man pages are embedded — read them with `unpin man iproute2 ip-route`.

## Build locally

```bash
nix build github:unpins/iproute2
./result/bin/iproute2 --unpin-program=ip -V
```

Or run directly:

```bash
nix run github:unpins/iproute2 -- --unpin-program=ip -V
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/iproute2/releases) page has standalone binaries for manual download.

## Build notes

- **Platform:** Linux only (netlink).
- **BPF:** `ip link … xdp obj` and `tc … bpf obj` load BPF object files through the bundled libbpf.
- **Name tables:** `rt_tables`, `rt_protos`, `rt_scopes`, `rt_realms`, `rt_dsfield`, `group`, `nl_protos`, `bpf_pinning` and `tc`'s `ematch_map` are read from `/etc/iproute2`, then `/usr/share/iproute2`, as a distro install does; when neither has one, upstream's copy is embedded. So names and the `tc` ematches (`basic match 'cmp(…)'`, …) work on a host without iproute2, and a table you edit in `/etc/iproute2` still applies.
- **netem tables:** the `normal`, `pareto`, `paretonormal` and `experimental` delay distributions are embedded. A table in `TC_LIB_DIR` or `/usr/lib/tc` takes precedence.
- **`tc` `ipt` and `ipset` ematches:** not built. nixpkgs' static build leaves out the xtables support both are compiled with; `ipt` would also need libxtables to load each iptables match as a plugin at run time.
- **Tests:** iproute2's test suite runs on native builds (0 failures under static-musl) and is skipped on cross targets the build host can't execute. Four tests are left out: two `ip netns` tests that create `/var/run/netns`, the `bareudp` test (a kernel module Debian does not build), and the `ip tunnel` test, whose ioctl only loads `ip_gre` for the host's root.
