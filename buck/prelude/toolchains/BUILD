
download.multi_file({
    "nixpkgs.tar.gz": {
        "url": "https://github.com/nixos/nixpkgs/archive/{}.tar.gz"
            .format("962d920b8dff4607dd27d33c36c88e4882f62a96"), # master @ 2023-04-17
        "hash": "sha256-VhcLZn+Y27qyJbeC73YH2c4XhIE5ipDDwtBydxjmtw8=",
        "visibility": [ 'PUBLIC', 'prelude//toolchains/...'],
    },

    # Overlays come after this. These must be sync'd with nixpkgs.bzl; see
    # [ref:add-nixpkgs-overlay] for more.
    "nixpkgs-overlay-rust.tar.gz": {
        "url": "https://github.com/oxalica/rust-overlay/archive/{}.tar.gz"
            .format("ffe47b90076067ad5dc25fe739d95a463bdf3c59"), # master @ 2023-04-16
        "hash": "sha256-XU8xT/hQrg5R1MgUPXOKeqBxiiOYTki758cQc4U8OUs=",
        "visibility": [ 'PUBLIC', 'prelude//toolchains/...'],
    }
})
