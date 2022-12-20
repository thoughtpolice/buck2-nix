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
          postPatch = "cp ${./Cargo.lock} Cargo.lock";
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
