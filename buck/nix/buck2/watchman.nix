{ stdenv, gcc12, gcc12Stdenv
, fetchurl, fetchFromGitHub
, rpmextract
, autoPatchelfHook
, openssl
, zlib, bzip2, xz, lz4, snappy, zstd
, libevent
, libunwind
, pcre2
, glog, gflags, gtest, cmake
, boost174
, libsodium
, double-conversion
}:

let
  version = "2022.12.19.00";

  file = {
    x86_64-linux = "watchman-20221218.010722.0-1.fc36.x86_64.rpm"; # XXX FIXME (aseipp): name is wrong?
  }."${stdenv.hostPlatform.system}" or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  baseurl = "https://github.com/facebook/watchman/releases/download";

  dlbin = sha256: fetchurl {
    url = "${baseurl}/v${version}/${file}";
    sha256 = sha256."${stdenv.hostPlatform.system}";
  };

  glog0 = stdenv.mkDerivation rec {
    pname = "glog";
    version = "0.4.0";

    src = fetchFromGitHub {
      owner = "google";
      repo = "glog";
      rev = "v${version}";
      hash = "sha256-K3X199xY2uLDeNeScDufu1tRemF05ZwYrH25G6Oqo/U=";
    };

    nativeBuildInputs = [ cmake ];
    buildInputs = [ gtest ];
    propagatedBuildInputs = [ gflags ];

    cmakeFlags = [ "-DBUILD_SHARED_LIBS=ON" ];
  };
in
gcc12Stdenv.mkDerivation {
  pname = "fbwatchman";
  inherit version;

  src = dlbin {
    x86_64-linux = "sha256-259AKteVefGs+bF7sE3PXE8jtdZ4BnOoqZKu+Bvt8Hs=";
  };

  unpackPhase = "rpmextract $src";

  buildInputs = [
    openssl libevent glog0 gflags libsodium
    zlib bzip2 xz lz4 snappy zstd gcc12.cc.lib
    libunwind pcre2 boost174 double-conversion
  ];
  nativeBuildInputs = [ autoPatchelfHook rpmextract ];
  dontConfigure = true;

  installPhase = ''
    ls usr/local
    mkdir -p $out
    mv usr/local/bin/ $out/bin
  '';
}
