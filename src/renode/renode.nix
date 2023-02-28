{ stdenv
, lib
, fetchurl
, makeWrapper

, glibcLocales
, python3Packages
, fetchFromGitHub

, gtk2
, gtk2-x11
, pcre
, glib
, libffi
}:

let

  rpath = lib.makeLibraryPath [
    stdenv.cc.libc
    gtk2
    gtk2-x11
    pcre
    glib
    libffi
  ];

  our-robotframework = python3Packages.buildPythonPackage rec {
    pname = "robotframework";
    version = "4.0.1";

    src = fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "refs/tags/v${version}";
      sha256 = "sha256-JgblsosNe84ByOPyTKPEC6JqWFtPIi+KN1rDTDWAd9o=";
    };

    nativeCheckInputs = with python3Packages; [ jsonschema ];

    patchPhase = ''
      substituteInPlace ./src/robot/output/librarylogger.py \
        --replace 'threading.currentThread().getName()' 'threading.current_thread().name'
      substituteInPlace ./src/robot/running/signalhandler.py \
        --replace 'currentThread' 'current_thread' \
        --replace 'getName()' 'name'
    '';

    checkPhase = "python3 utest/run.py";
  };

  pythonLibs = with python3Packages; makePythonPath [
    psutil
    our-robotframework
    pyyaml
  ];

in

stdenv.mkDerivation rec {
  pname = "renode";
  version = "1.13.2";

  src = fetchurl {
    url = "https://github.com/${pname}/${pname}/releases/download/v${version}/renode-${version}.linux-portable.tar.gz";
    hash = "sha256-OvOlOELZ1eR3DURCoPe+WCvVyVm6DPKNcC1V7uauCjY=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # don't strip, so we don't accidentally break the rpaths, somehow
  dontStrip = true;

  buildPhase = ":";
  installPhase = ''
    mkdir -p $out/{bin,libexec/renode}

    mv * $out/libexec/renode
    mv .renode-root $out/libexec/renode
    chmod +x $out/libexec/renode/*.so

    cat > $out/bin/renode <<EOF
    #!${stdenv.shell}
    export LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive
    export PATH="$out/libexec/renode:\$PATH"
    exec renode "\$@"
    EOF

    cat > $out/bin/renode-test <<EOF
    #!${stdenv.shell}
    export LOCALE_ARCHIVE=${glibcLocales}/lib/locale/locale-archive
    export PYTHONPATH="${pythonLibs}:\$PYTHONPATH"
    export PATH="$out/libexec/renode:\$PATH"
    exec renode-test "\$@"
    EOF

    chmod +x $out/bin/renode $out/bin/renode-test
  '';

  # for some reason, autoPatchelfHook doesn't handle libc on these binaries? so we have to
  # apply the rpath to libc manually, anyway.
  postFixup = ''
    for x in renode libgdksharpglue-2.so libglibsharpglue-2.so libgtksharpglue-2.so libllvm-disas.so libmono-btls-shared.so; do
      p=$out/libexec/renode/$x
      patchelf --add-rpath ${rpath} $p
    done

    substituteInPlace $out/libexec/renode/renode-test \
      --replace '$PYTHON_RUNNER' '${python3Packages.python}/bin/python3'
  '';

  meta = {
    description = "Virtual development framework for complex embedded systems";
    homepage = "https://renode.org";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ thoughtpolice ];
    platforms = [ "x86_64-linux" ];
  };
}
