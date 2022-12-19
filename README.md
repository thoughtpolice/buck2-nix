# buck2-nix

An experiment to integrate **[Buck]**, **[Sapling]**, and **[Nix]** together in
a harmonious way. Because this uses a pre-release Buck as well as our own Buck
prelude to integrate with Nix, we're on our own.

You **MUST** have **[direnv]** installed. Everything else &mdash; including the
correct tool versions &mdash; will be populated in your shell by `direnv`
automatically when you move here.

There are some design notes in the `buck/` directory. This is an experiment.
Nothing is stable and everything is permitted. Do not taunt happy fun ball.

## requirements

1) `direnv` installed into your shell
2) nix 2.12.0
3) `trusted-users` includes your `$USER`

`direnv` will warn you if either 2 or 3 are not satisfied when you move into
this directory. See **[.envrc](/blob/main/.envrc)** for details.

## commands

Clone with `sl`, since you probably don't have it installed. Moving into the
repo will cause `direnv` to activate and populate tools.

- `nix run github:nixos/nixpkgs/nixpkgs-unstable#sapling -- clone https://github.com/thoughtpolice/buck2-nix`
- `cd buck2-nix`

Build whole repo; this downloads all tools needed on demand, including Nix
tools, from the binary cache (which is why you must be a trusted user)

- `buck build ...`

Clean, then kill daemons

- `buck clean`

<!-- refs -->

[Buck]: https://github.com/facebookincubator/buck2
[Sapling]: https://sapling-scm.com
[Nix]: https://nixos.org
[direnv]: https//direnv.net
