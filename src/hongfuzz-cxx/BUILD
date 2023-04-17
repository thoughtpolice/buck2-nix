load("@prelude//toolchains/cxx/main.bzl", "cxx")

cxx.binary(
    name = "get_first_cap",
    sources = glob(["*.c"]),
    headers = glob(["*.h"]),
    toolchain = "@prelude//toolchains/cxx:clang-stable",
)

cxx.binary(
    name = "get_first_cap-fuzz",
    sources = glob(["*.c"], exclude=["main.c"]),
    headers = glob(["*.h"]),
    cflags = ["-fsanitize=fuzzer"],
    toolchain = "@prelude//toolchains/cxx:clang-honggfuzz",
)
