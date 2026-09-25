# iproute2

[iproute2](https://wiki.linuxfoundation.org/networking/iproute2) — the Linux networking tools: `ip` (addresses, links, routes, rules, neighbours, namespaces, tunnels), `ss` (sockets), `tc` (traffic control), `bridge`, `devlink`, `rdma`, `dcb`, `vdpa`, `tipc`, `dpll`, `netshaper` and the `nstat`/`ifstat`/`lnstat`/`rtacct` counters. A single self-contained binary, built natively for Linux.

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

The section-8 pages are embedded — read them with `unpin man iproute2 ip-route`.

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
- **Name tables:** `ip` reads `rt_tables`, `rt_protos` and the other name tables from `/etc/iproute2`, then `/usr/share/iproute2`, as a distro install does; the built-in names (`main`, `local`, `kernel`, …) work without them.
- **`tc` `ipt` ematch:** not built. It matches packets with iptables extensions, which libxtables loads as plugins at run time.
