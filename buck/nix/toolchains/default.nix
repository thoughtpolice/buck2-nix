{ pkgs }:

{
    zip = pkgs.zip;
    tar = pkgs.coreutils;

    rust-stable = pkgs.rust-bin.stable.latest.default;
    rust-nightly = pkgs.rust-bin.nightly.latest.default;
}
