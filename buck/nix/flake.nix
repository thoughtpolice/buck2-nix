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
    extra-substituters = "https://buck2-nix-cache.aseipp.dev/";
    trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= buck2-nix-preview.aseipp.dev-1:sLpXPuuXpJdk7io25Dr5LrE9CIY1TgGQTPC79gkFj+o=";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    let
      systems = with flake-utils.lib; [
        system.x86_64-linux
        system.aarch64-linux
        system.x86_64-darwin
        system.aarch64-darwin
      ];

    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];

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
          packages = flake-utils.lib.flattenTree rec {
            # These are all tools from upstream
            inherit (pkgs.gitAndTools) gh git;
            inherit (pkgs)
              tagref sapling jq getopt jujutsu
              ;

            buck2 = pkgs.callPackage ./buck2 { };
          };

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
      });
}
