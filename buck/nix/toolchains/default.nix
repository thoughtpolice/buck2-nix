{ pkgs }:

{
    zip = pkgs.zip;
    tar = pkgs.coreutils;

    nodejs = pkgs.nodejs;
    lua = pkgs.lua5_3;

    rust-stable = pkgs.rust-bin.stable.latest.default;
    rust-nightly = pkgs.rust-bin.nightly.latest.default;
}
