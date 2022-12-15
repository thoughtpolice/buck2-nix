{ fetchFromGitHub
, rust-bin
, makeRustPlatform
, protobuf
, pkg-config
, openssl
, sqlite
}:

let
  rustChannel = "nightly";
  rustVersion = "2022-09-27"; # XXX NOTE: sync with rust-toolchain

  my-rust-bin = rust-bin."${rustChannel}"."${rustVersion}".default;

  rustPlatform = makeRustPlatform {
    rustc = my-rust-bin;
    cargo = my-rust-bin;
  };

in rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2022.12.14";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "10bd96ddf90e0aff13d9625e38eff0e3d0d0e75f";
    hash = "sha256-vnjETGaEuAul7ncoVRyDQfUt90DZu18TeFoYA2AIcAg=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {};
  };

  doCheck = false;
  postPatch = "cp ${./Cargo.lock} Cargo.lock";

  postInstall = ''
    mv $out/bin/buck2     $out/bin/buck
    ln -sfv $out/bin/buck $out/bin/buck2
    mv $out/bin/starlark  $out/bin/buck-starlark
    mv $out/bin/read_dump $out/bin/buck-read_dump
  '';

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl sqlite ];
}
