# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: © 2022-2023 Austin Seipp

# "Development environment flake." This is used, along with direnv, to populate
# a shell with all the necessary setup to get things rolling in an incremental
# fashion.

{
  # Flake inputs. These are the only external inputs we use to build the system
  # and describe all further build configuration.
  #
  # THIS LIST SHOULD NOT BE EXPANDED WITHOUT GOOD REASON. If you need to add
  # something, think hard about whether or not it can be achieved. Why? Because
  # every dependency that comes from elsewhere is a (potential) liability in the
  # quality control and security departments.
  #
  # The fact of the matter is that even the most mandatory input of all,
  # `nixpkgs`, already expose massive amount of surface area to the project and
  # downstream consumers. This is a good thing due to its versatility and
  # support, but it also means that we need to hedge our bets in other places.
  # Think of it like an investment: we already spent a good chunk of change, so
  # we don't want to spend too much more. If the option is "Bring in a 3rd party
  # dependency" or "Write 100 lines of Nix and stuff them in the repository",
  # the second one is almost always preferable.
  #
  # Furthermore, for the sake of maintainability and QA, we also make sure any
  # dependency has a consistent set of transitive dependencies.
  #
  # (Honestly, it'd be great if flake-utils could go away, but we need it anyway
  # for rust-overlay, alas.)
  #
  # Moral of the story: DO NOT EXPAND THIS INPUT LIST WITHOUT GOOD REASON.
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

  # [tag:custom-nix-config] Custom configuration. We use this to add our own
  # user level customization to `nix.conf`, primarily for the binary cache, and
  # is the primary reason we require the developer to be in 'trusted-users'.
  nixConfig = {
    # see [ref:cache-url-warning]
    extra-substituters = "https://buck2-nix-cache.aseipp.dev/";

    # one day, we won't need our own key when we can use [ref:ca-derivations]...
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

        # The imported nixpkgs package set; all usages come from here with
        # overlays nicely applied.
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) myOverlay ];

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
              coreutils curl # downloading and fundamental scripts
              tagref sapling jq getopt jujutsu # utilities
              cargo nix-prefetch-git # XXX FIXME (aseipp): needed by update.sh for buck2; get rid of somehow...
              ;

            # Finally, any globally useful tools we package here go next. This is primarily
            # buck, in our case...
            buck2 = pkgs.callPackage ./buck2 { };
          }) // (pkgs.lib.optionalAttrs (system == flake-utils.lib.system.x86_64-linux) {
            # watchman is only supported on x86_64-linux for now; in theory it
            # should be possible to port to aarch64-linux through the github
            # release...
            watchman = pkgs.callPackage ./buck2/watchman.nix { };
          });

          # Automatically incorporate all toolchains. It is currently expected
          # that this is a raw attrset of unique names as keys and derivations
          # as values (i.e. no nested derivations or anything like that for now)
          toolchains = import ./toolchains { inherit pkgs; };

          # The default Nix shell. This is populated by direnv and used for the
          # interactive console that a developer uses when they use buck2, sl,
          # et cetera.
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = builtins.attrValues packages ++ [
              # add a convenient alias for Super Smartlog. We can't put this in
              # direnv so easily because it evaluates .envrc in a subshell.
              # Slightly worse overhead, but oh well...
              (pkgs.writeShellScriptBin "ssl" ''
                exec ${pkgs.sapling}/bin/sl ssl "$@"
              '')

              # add a convenient alias for 'buck bxl' on some scripts. note that
              # the 'bxl' cell location can be changed in .buckconfig without
              # changing the script
              (pkgs.writeShellScriptBin "bxl" ''
                exec ${jobs.packages.buck2}/bin/buck bxl "bxl//top.bxl:$1" -- "''${@:2}"
              '')
            ];
          };
        };

        # Flatten the hierarchy; mostly used to ensure we build everything...
        flatJobs = flake-utils.lib.flattenTree rec {
          packages = jobs.packages // { recurseForDerivations = true; };
          toolchains = jobs.toolchains // { recurseForDerivations = true; };
        };

      in rec {
        inherit (jobs) devShells;
        packages = rec {
          # By default, build all the packages in the tree when just running
          # 'nix build'; useful for various development tasks, since it ensures
          # a fully 'clean' closure builds. But we obviously don't use it for
          # devShells...
          default = world;

          # List of all attributes in this whole flake; useful for the cache
          # upload scripts, and also CI and other things probably...
          attrs = pkgs.writeText "attrs.txt" (pkgs.lib.concatStringsSep "\n" ([ "world" ] ++ (builtins.attrNames flatJobs)));

          # XXX FIXME (aseipp): unify this with 'attrs' someday...
          world = pkgs.writeText "world.json" (builtins.toJSON {
            shellPackages = jobs.packages;
            toolchainPackages = jobs.toolchains;
          });

          # Merge in flatJobs, so that when we do things like 'nix flake show'
          # or try to list and build all attrs, we can see all the packages and
          # toolchains, et cetera.
        } // flatJobs;

        # Makes the setup app a 'nix run'-able tool.
        apps.setup = flake-utils.lib.mkApp { drv = pkgs.our_setup_tool; };
      });
}
