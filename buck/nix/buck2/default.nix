{ fetchFromGitHub
, rustPlatform
, protobuf
, pkg-config
, openssl
, sqlite
}:

rustPlatform.buildRustPackage rec {
  pname = "buck2";
  version = "unstable-2022.12.09";

  src = fetchFromGitHub {
    owner = "facebookincubator";
    repo = "buck2";
    rev = "5e7af16ffaa73a5c8229f7e33538be6119d57019";
    hash = "sha256-7Sg08djjb3RgooGa/JJUVNfE6qLCFxQDM8EQd/8xOwQ=";
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
