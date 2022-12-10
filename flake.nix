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

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    let
      systems = with flake-utils.lib; [
        system.x86_64-linux
        system.aarch64-linux
        system.x86_64-darwin
        system.aarch64-darwin
      ];

      rustChannel = "nightly";
      rustVersion = "2022-09-27";

    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rust-bin = pkgs.rust-bin."${rustChannel}"."${rustVersion}".default;

        rustPlatform = pkgs.makeRustPlatform {
          rustc = rust-bin;
          cargo = rust-bin;
        };

        jobs = rec {
          packages = flake-utils.lib.flattenTree rec {

            testing = pkgs.runCommand "testing" { } ''
              set -x
              mkdir -p $out/bin $out/share
              ln -s ${pkgs.hello}/bin/hello $out/bin/testing
            '';

            inherit (pkgs)
              tagref sapling
              ;
            inherit (pkgs.gitAndTools) gh;

            buck2 = rustPlatform.buildRustPackage rec {
              pname = "buck2";
              version = "unstable-2022.12.09";

              src = pkgs.fetchFromGitHub {
                owner = "facebookincubator";
                repo = "buck2";
                rev = "5e7af16ffaa73a5c8229f7e33538be6119d57019";
                hash = "sha256-7Sg08djjb3RgooGa/JJUVNfE6qLCFxQDM8EQd/8xOwQ=";
              };

              cargoLock = {
                lockFile = ./nix/buck2/Cargo.lock;
                outputHashes = {};
              };

              doCheck = false;
              postPatch = "cp ${./nix/buck2/Cargo.lock} Cargo.lock";

              postInstall = ''
                mv $out/bin/starlark  $out/bin/buck2-starlark
                mv $out/bin/read_dump $out/bin/buck2-read_dump
              '';

              nativeBuildInputs = [ pkgs.protobuf pkgs.pkg-config ];
              buildInputs = [ pkgs.openssl pkgs.sqlite ];
            };

            repro-test = pkgs.runCommand "unstable" { } ''
              touch $out
             #echo $RANDOM > $out
            '';
          };

          apps = rec {
            default = testing;
            testing = { type = "app"; program = "${packages.testing}/bin/testing"; };
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with packages; [ buck2 tagref sapling gh ];
          };
        };
      in {
        inherit (jobs) apps devShells;
        packages = flake-utils.lib.flattenTree rec {
          default = world;
          world = with pkgs.lib; let
            refs = mapAttrsToList nameValuePair jobs.packages;
            cmds = concatStringsSep "\n" (map (x: ''
              x=$(basename ${x.value})
              echo $x >> $out/nix-refs
              echo ${x.name} >> $out/$x
            '') refs);
          in pkgs.runCommand "world" { } ''
            set -feu; mkdir $out
            ${cmds}
          '';
        } // jobs.packages;
      });
}
