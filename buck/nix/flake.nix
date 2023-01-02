{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  nixConfig = {
    # see [ref:cache-url-warning]
    extra-substituters = "https://buck2-nix-cache.aseipp.dev/";
    trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= buck2-nix-preview.aseipp.dev-1:sLpXPuuXpJdk7io25Dr5LrE9CIY1TgGQTPC79gkFj+o=";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    let
      systems = with flake-utils.lib; [
        system.x86_64-linux
        system.aarch64-linux
      ];

    in flake-utils.lib.eachSystem systems (system:
      let
        # This overlay is used to add the setup tool to the normal package set.
        myOverlay = (final: _: {
          our_setup_tool = final.callPackage (
            { stdenv, rustPlatform }:

            rustPlatform.buildRustPackage rec {
              name = "setup";
              src = self;
              cargoLock.lockFile = ./setup/Cargo.lock;
              # we have to cd into this directory because, when 'nix run' is used to
              # run the setup tool, the ?dir parameter only refers to where the
              # flake/nix code is located; the build process otherwise still execues
              # within the git root dir (e.g. so ${self} points to the git root) and
              # so we need to move into place before building rust code
              #
              # NOTE: this might break local 'nix run .' invocations
              #
              # XXX FIXME (aseipp): should this be filed as a nix bug?
              postPatch = "cd buck/nix/setup";
            }) { };
        });

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import rust-overlay)
            myOverlay
          ];

          # [tag:ca-derivations] One day, we'll enable content-addressable
          # derivations for all outputs here. This should significantly help any
          # and all toolchain support in a number of ways, primarily through:
          #
          #  - early cut-off optimization
          #  - self-authenticating paths (no more signing needed!)
          #
          # ideally, in a utopia, this would be the only way Nix worked in the
          # future, but it's too buggy for right now...
          #
          # XXX FIXME (aseipp): enable this, one day...
          config.contentAddressedByDefault = false;
        };

        jobs = rec {
          packages = flake-utils.lib.flattenTree (rec {
            # These are all tools from upstream
            inherit (pkgs.gitAndTools) gh git;
            inherit (pkgs)
              tagref sapling jq getopt jujutsu
              cargo # XXX FIXME (aseipp): needed by update.sh for buck2; get rid of somehow...
              ;

            buck2 = pkgs.callPackage ./buck2 { };
          }) // (pkgs.lib.optionalAttrs (system == flake-utils.lib.system.x86_64-linux) {
	    # watchman is only supported on aarch64-linux for now; in theory it
	    # should be possible to port through the github release
            watchman = pkgs.callPackage ./buck2/watchman.nix { };
          });

          toolchains = import ./toolchains { inherit pkgs; };

          # The default Nix shell. This is populated by direnv and used for the
          # interactive console that a developer uses when they use buck2, sl,
          # et cetera.
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = builtins.attrValues packages ++ [
              # add a convenient alias for Super Smartlog. We can't put this in
              # direnv so easily because it evaluates .envrc in a subshell.
              # Slightly worse overhead, but oh well...
              (pkgs.writers.writeBashBin "ssl" ''
                #!${pkgs.runtimeShell}
                exec ${pkgs.sapling}/bin/sl ssl "$@"
              '')

            ];
          };
        };

        flatJobs = flake-utils.lib.flattenTree rec {
          packages = jobs.packages // { recurseForDerivations = true; };
          toolchains = jobs.toolchains // { recurseForDerivations = true; };
        };
      in rec {
        inherit (jobs) devShells;
        packages = rec {
          default = world;

          # XXX FIXME (aseipp): unify this with 'attrs' someday...
          world = pkgs.writeText "world.json" (builtins.toJSON {
            shellPackages = jobs.packages;
            toolchainPackages = jobs.toolchains;
          });

          attrs = pkgs.writeText "attrs.txt" (pkgs.lib.concatStringsSep "\n" ([ "world" ] ++ (builtins.attrNames flatJobs)));
        } // flatJobs;

        apps.setup = flake-utils.lib.mkApp { drv = pkgs.our_setup_tool; };
      });
}
