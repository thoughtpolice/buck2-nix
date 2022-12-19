{ pkgs }:

{
    inherit (pkgs)
        bash zip nodejs
        ;

    tar = pkgs.coreutils;
    lua = pkgs.lua5_3;

    rust-stable = pkgs.rust-bin.stable.latest.default;
    rust-nightly = pkgs.rust-bin.nightly.latest.default;
}
