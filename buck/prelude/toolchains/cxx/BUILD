load(":main.bzl", "cxx")

cxx.clang_toolchain(
    name = "clang-stable",
    version = "15",
    visibility = [ "root//..." ],
)

cxx.clang_toolchain(
    name = "clang-honggfuzz",
    version = "12",
    pkg = "honggfuzz",
    binary = "hfuzz-clang",
    visibility = [ "root//..." ],
)
