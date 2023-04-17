load("@prelude//toolchains/nixpkgs.bzl", "nix")

nix.rules.build(
    name = "scryer",
    expr = "pkgs.scryer-prolog",
    binary = "bin/scryer-prolog",
    visibility = [ "root//..." ],
)
