load("@prelude//basics/download.bzl", "download")

download.tarball(
    name = "nixpkgs-src",
    url = "https://github.com/nixos/nixpkgs/archive/{}.tar.gz"
        .format("962d920b8dff4607dd27d33c36c88e4882f62a96"), # master @ 2023-04-17
    hash = "sha256-5gFx8BFvG/1QDoEFSn1FPmGGs2a2sgL0thSCBQKTtkY=",
    visibility = [ 'PUBLIC', 'prelude//toolchains/...'],
)

download.tarball(
    name = "nixpkgs-overlay-rust",
    url = "https://github.com/oxalica/rust-overlay/archive/{}.tar.gz"
        .format("ffe47b90076067ad5dc25fe739d95a463bdf3c59"), # master @ 2023-04-16
    hash = "sha256-47DFtN5PX05eD8ObImkSu2W0hyyZ5cK1Tl9EvmW2NnU=",
    visibility = [ 'PUBLIC', 'prelude//toolchains/...'],
)
