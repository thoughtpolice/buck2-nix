load(":main.bzl", "rust")

rust.toolchain(
    name = "rust-stable",
    channel = "stable",
    version = "1.67.0",
    visibility = [ "root//..." ],
)

rust.toolchain(
    name = "rust-nightly",
    channel = "nightly",
    version = "2023-02-03",
    visibility = [ "root//..." ],
)

rust.toolchain(
    name = "rust-nightly-arm",
    channel = "nightly",
    version = "2023-02-03",
    extensions = [ "rust-src" ],
    targets = [ "arm-unknown-linux-gnueabihf" ],
    visibility = [ "root//..." ],
)
