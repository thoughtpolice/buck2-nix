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
  rustVersion = "2022-09-27";

  my-rust-bin = rust-bin."${rustChannel}"."${rustVersion}".default.override {
    extensions = [ "rust-analyzer" ];
  };

  rustPlatform = makeRustPlatform {
    rustc = my-rust-bin;
    cargo = my-rust-bin;
  };

in rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2023-01-12";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "1207d5d103094a2bb837087442593d73db2394ff";
    hash = "sha256-HG/xB6iJzUTUo15FGPeJ4vE6tJAUnJqQdlME7V4iLqk=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {};
  };

  BUCK2_BUILD_PROTOC = "${protobuf}/bin/protoc";
  BUCK2_BUILD_PROTOC_INCLUDE = "${protobuf}/include";

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl sqlite ];

  doCheck = false;

  patches = [
    # XXX FIXME (aseipp): Disable watchman support entirely and always short-
    # circuit to 'notify' on aarch64; this lets us keep things compatible on
    # both aarch64-linux and x86_64-linux
    ./aarch64-linux-notify-hack.patch
  ];

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
}
