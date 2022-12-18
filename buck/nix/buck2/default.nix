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
  version = "unstable-2022.12.18";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "eb3de6fbbc7913882e732826d3381a969ed8bf2a";
    hash = "sha256-pT5DXGEClLJjrAd5TGId8Dr3XyUBEf7KJR2hPvNsQZw=";
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
