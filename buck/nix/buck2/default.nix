{ fetchFromGitHub
, rustPlatform
, protobuf
, pkg-config
, openssl
, sqlite
}:

rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2022.12.13";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "423e82411c602f721d262d7d34a550e96a9321fc";
    hash = "sha256-p5lPWPnLXTnZ/Oz9hN3U8Ublq0sTsrkxwyfQfHj1cj0=";
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
