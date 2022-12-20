{
  description = "XXX FIXME (aseipp): test installer";

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
    let myOverlay = (final: _: {
      installer = final.callPackage (
        { stdenv
        , rustPlatform
        }:

        rustPlatform.buildRustPackage rec {
          name = "installer";
          src = self;
          cargoLock.lockFile = ./Cargo.lock;
          # we have to cd into this directory because, when 'nix run' is used to
          # run the installer, the ?dir parameter only refers to where the
          # flake/nix code is located; the build process otherwise still execues
          # within the git root dir (e.g. so ${self} points to the git root) and
          # so we need to move into place before building rust code
          #
          # NOTE: this might break local 'nix run .' invocations
          #
          # XXX FIXME (aseipp): should this be filed as a nix bug?
          postPatch = "cd installer";
        }) { };
    });
    in flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) myOverlay ];
      }; in rec {
        packages.installer = pkgs.installer;
        apps.installer = flake-utils.lib.mkApp { drv = pkgs.installer; };

        defaultPackage = packages.installer;
        defaultApp = apps.installer;
      }
    );
}
