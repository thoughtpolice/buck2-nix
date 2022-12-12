# buck2-nix

An experiment to integrate **[Buck]**, **[Sapling]**, and **[Nix]** together in
a harmonious way. Because this uses a pre-release Buck as well as our own Buck
prelude to integrate with Nix, we're on our own.

You **MUST** have **[direnv]** installed. Everything else &mdash; including the
correct tool versions &mdash; will be populated in your shell by `direnv`
automatically when you move here.

This is an experiment. Nothing is stable and everything is permitted. Do not
taunt happy fun ball.

## commands

clone with `sl`, since you probably don't have it installed

- `nix run github:nixos/nixpkgs/nixpkgs-unstable#sapling -- clone https://github.com/thoughtpolice/buck2-nix`

build repo

- `buck2 build ...`

clean, then kill all daemons

- `rm -r $(sl root)/buck-out; killall \.sl-wrapped buck2`

<!-- refs -->

[Buck]: https://github.com/facebookincubator/buck2
[Sapling]: https://sapling-scm.com
[Nix]: https://nixos.org
[direnv]: https//direnv.net
