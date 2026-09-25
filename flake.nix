{
  description = "iproute2 (ip, ss, tc, bridge, …) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "iproute2";
      binName = "iproute2";
      smoke = [ "--unpin-program=ip" "-V" ];
      smokePattern = "^ip utility, iproute2-[0-9]+\\.[0-9]+";
      engine = "unpin-llvm";
      multicall = {
        programs = map (name: { inherit name; }) [
          "ip" "rtmon" "bridge" "tc" "ss" "nstat" "ifstat" "rtacct" "arpd"
          "devlink" "rdma" "dcb" "vdpa" "tipc" "genl" "dpll" "netshaper"
        ] ++ [ { name = "lnstat"; aliases = [ "rtstat" "ctstat" ]; } ];
      };
      license = "GPL-2.0-only";
      linuxOnly = true; # netlink
      # nixpkgs' static build drops libbpf/elfutils (BPF object loading in
      # `ip link … xdp obj` and `tc … bpf obj`); upstream also probes libselinux
      # (ss -Z), libtirpc (ss RPC info) and libcap (ip vrf exec).
      # Dropped: the tc `ipt` ematch, since libxtables loads each iptables match
      # as a plugin at run time.
      build = pkgs:
        let
          p = pkgs.pkgsStatic;
          # nixpkgs marks elfutils static-bad: its build always links libelf.so,
          # libdw and the eu-* tools. libbpf and iproute2 need only libelf.a, so
          # build just that. debuginfod and the demangler serve libdw.
          elfutils = (p.elfutils.override { enableDebuginfod = false; }).overrideAttrs (o: {
            # configure calls pkg-config for zstd even without debuginfod.
            nativeBuildInputs = o.nativeBuildInputs ++ [ pkgs.buildPackages.pkg-config ];
            # The __thread probe links a -shared DSO, which the engine does not
            # produce on i686; libelf.a is static, where __thread works.
            configureFlags = o.configureFlags ++ [ "--disable-demangler" "ac_cv_tls=yes" ];
            outputs = [ "out" "dev" ];
            # libelf.a folds in libeu's objects. libelf checksums with its own
            # __libelf_crc32, and libeu's crc32 would collide with zlib's.
            buildPhase = ''
              runHook preBuild
              make -C lib
              sed -i 's/\bcrc32\.o\b//' lib/libeu.manifest
              make -C libelf libelf.a
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              make -C libelf install-libLIBRARIES install-includeHEADERS
              install -Dm644 config/libelf.pc -t $out/lib/pkgconfig
              runHook postInstall
            '';
            meta = o.meta // { badPlatforms = [ ]; };
          });
          # --enable-rpcdb: getrpcbynumber (ss names the RPC programs it finds)
          # lives in glibc, not musl, so libtirpc has to carry it. ss queries
          # the local rpcbind with AUTH_NONE; RPCSEC_GSS would only add krb5.
          libtirpc = p.libtirpc.overrideAttrs (o: {
            configureFlags = (o.configureFlags or [ ]) ++ [ "--enable-rpcdb" "--disable-gssapi" ];
            propagatedBuildInputs = p.lib.filter (d: (d.pname or "") != "krb5") (o.propagatedBuildInputs or [ ]);
            env = builtins.removeAttrs (o.env or { }) [ "KRB5_CONFIG" ];
          });
          libbpf = (p.libbpf.override { inherit elfutils; }).overrideAttrs (o: {
            makeFlags = o.makeFlags ++ [ "BUILD_STATIC_ONLY=y" ];
          });
        in
        p.iproute2.overrideAttrs (old: {
          # pkgsStatic moves buildInputs here. python3 serves only the routel
          # script, which is not shipped; iptables only the dropped ematch.
          propagatedBuildInputs = p.lib.filter (d: !(p.lib.elem (d.pname or "") [ "python3" "iptables" ])) old.propagatedBuildInputs;
          buildInputs = old.buildInputs ++ [ libbpf elfutils p.zlib p.zstd p.libselinux libtirpc p.libcap ];
          makeFlags = old.makeFlags ++ [
            # Upstream's defaults under PREFIX=/usr, where distros install the
            # netem distribution tables and the rt_* name tables; the nixpkgs
            # build points both at its own store path.
            "LIBDIR=/usr/lib"
            "CONF_USR_DIR=/usr/share/iproute2"
          ];
          postPatch = old.postPatch + ''
            # nstat/ifstat/rtacct/arpd compile and link in one `cc -o x x.c`, and
            # the engine takes a program's objects from its link line. Split them;
            # make's built-in rule compiles x.o with the same CFLAGS.
            sed -E -i \
              -e 's/^(nstat|ifstat|rtacct|arpd): \1\.c$/\1: \1.o/' \
              -e 's/-o (nstat|ifstat|rtacct|arpd) \1\.c /-o \1 \1.o /' \
              misc/Makefile
            # `tc qdisc … netem delay … distribution normal` reads its table from
            # LIBDIR/tc/<name>.dist. Keep that lookup first (and TC_LIB_DIR), and
            # fall back to the four tables upstream generates, compiled in.
            substituteInPlace tc/q_netem.c \
              --replace-fail '#include "tc_common.h"' '#include "tc_common.h"
            #include "netem_dists.h"' \
              --replace-fail '	f = fopen(name, "r");
            	if (f == NULL) {' '	f = fopen(name, "r");
            	if (f == NULL)
            		f = netem_builtin_dist(type);
            	if (f == NULL) {'
          '';
          # configure assumes a pkg-config libbpf is libbpf.so and has `ip -V`
          # look for it in /proc/self/maps; here it is linked in, so the
          # compile-time version is the running one.
          postConfigure = (old.postConfigure or "") + ''
            sed -i '/-DLIBBPF_DYNAMIC/d' config.mk
          '';
          preBuild = (old.preBuild or "") + ''
            # netem is the one place upstream runs what it just built, so its
            # generators need the build machine's cc; a bare `make` here would
            # miss the HOSTCC that $makeFlags already carries.
            make -C netem HOSTCC="$CC_FOR_BUILD"
            {
              echo 'static const struct { const char *name, *data; } netem_dists[] = {'
              for d in normal pareto paretonormal experimental; do
                echo "{ \"$d\","
                sed 's/.*/"&\\n"/' netem/$d.dist
                echo '},'
              done
              echo '};'
              echo 'static FILE *netem_builtin_dist(const char *type) {'
              echo '  for (size_t i = 0; i < sizeof(netem_dists) / sizeof(netem_dists[0]); i++)'
              echo '    if (!strcmp(type, netem_dists[i].name))'
              echo '      return fmemopen((void *)netem_dists[i].data, strlen(netem_dists[i].data), "r");'
              echo '  return NULL;'
              echo '}'
            } > tc/netem_dists.h
          '';
          # routel (a Python script) is not shipped, and libnetlink.3 documents
          # an internal library; neither belongs in the embedded man set.
          postInstall = (old.postInstall or "") + ''
            for _o in $outputs; do
              rm -f "''${!_o}"/share/man/man8/routel.8* "''${!_o}"/share/man/man3/libnetlink.3*
            done
          '';
          installFlags = (old.installFlags or [ ]) ++ [
            "LIBDIR=$(out)/lib"
            "CONF_USR_DIR=$(out)/share/iproute2"
          ];
        });
    };
}
