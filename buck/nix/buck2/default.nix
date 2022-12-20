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
  version = "unstable-2022-12-20";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "5f4144051c11f091b648e4709d811fe514fa8191";
    hash = "sha256-FUORSq9mwT4T4njKIbmj8Eie2nwsxnT1qArMCgqGQyA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {};
  };

  doCheck = false;

  # Put in the Cargo.lock file.
  #
  # XXX NOTE (aseipp): Also, for now, suppress a really annoying 'tracing'
  # warning that makes the default build output uglier; once we self-bootstrap
  # buck2 with buck2 under Nix (ugh...) then we can get rid of this.
  postPatch = ''
    cp ${./Cargo.lock} Cargo.lock
    substituteInPlace buck2_server/src/daemon/common.rs \
      --replace 'tracing::warn!("Cargo build detected:' '//tracing::warn!("Cargo build detected:'
  '';

  postInstall = ''
    mv $out/bin/buck2     $out/bin/buck
    ln -sfv $out/bin/buck $out/bin/buck2
    mv $out/bin/starlark  $out/bin/buck-starlark
    mv $out/bin/read_dump $out/bin/buck-read_dump
  '';

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl sqlite ];
}
