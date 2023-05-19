{ lib
, fetchFromGitHub
, rust-bin
, makeRustPlatform
, protobuf
, pkg-config
, openssl
, sqlite
}:

let
  rustChannel = "nightly";
  rustVersion = "2023-03-07";

  my-rust-bin = rust-bin."${rustChannel}"."${rustVersion}".default.override {
    extensions = [ "rust-analyzer" ];
  };

  rustPlatform = makeRustPlatform {
    rustc = my-rust-bin;
    cargo = my-rust-bin;
  };

in rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2023-05-19";

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "buck2";
    rev = "ce861bf16cbd1ee39102ab39eabc56bed0aad66e";
    hash = "sha256-RLd1SYLstCViX58hisuxXNGKnWgvNCU2db9NrzhfUrY=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "perf-event-0.4.8" = "sha256-4OSGmbrL5y1g+wdA+W9DrhWlHQGeVCsMLz87pJNckvw=";
      "tonic-0.8.3" = "sha256-xuQVixIxTDS4IZIN46aMAer3v4/81IQEG975vuNNerU=";
      "hyper-proxy-0.10.0" = "sha256-MeEWEP9xcQlVO8EA0U1/0uRJrdJMqlthIZx4qdus8Mg=";
    };
  };

  BUCK2_BUILD_PROTOC = "${protobuf}/bin/protoc";
  BUCK2_BUILD_PROTOC_INCLUDE = "${protobuf}/include";

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl sqlite ];

  doCheck = false;
  dontStrip = true; # XXX (aseipp): cargo will delete dwarf info but leave symbols for backtraces

  patches = [ /* None, for now */ ];

  # Put the Cargo.lock file in the build.
  postPatch = "cp ${./Cargo.lock} Cargo.lock";

  postInstall = ''
    mv $out/bin/buck2     $out/bin/buck
    ln -sfv $out/bin/buck $out/bin/buck2
    mv $out/bin/starlark  $out/bin/buck2-starlark
    mv $out/bin/read_dump $out/bin/buck2-read_dump
  '';
}
