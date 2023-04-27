load("@prelude//toolchains/cxx/main.bzl", "cxx")

cxx.binary(
    name = "uffd-sample",
    sources = glob(["main.c"]),
    cflags = ["-std=c2x"],
)
