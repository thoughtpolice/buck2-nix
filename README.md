# buck2-nix

> **NOTE**: This repository is extremely experimental and may change radically.
> You probably don't want to be here unless you talk to me. Please see issue
> thoughtpolice/buck2-nix#1 for some design notes and feel free to provide
> input.

An experiment to integrate **[Buck2]**, **[Sapling]**, and **[Nix]** together in
a harmonious way. Because this uses a pre-release Buck as well as our own Buck
prelude to integrate with Nix, we're on our own.

You **MUST** have **[direnv]** installed. Everything else &mdash; including the
correct tool versions &mdash; will be populated in your shell by `direnv`
automatically when you move here.

There are some design notes in the `buck/` directory. This is an experiment.
Nothing is stable and everything is permitted. Do not taunt happy fun ball.

## requirements

1. `direnv` installed into your shell
2. nix 2.14.0 or newer
3. `trusted-users` includes your `$USER`

`direnv` will warn you if either 2 or 3 are not satisfied when you move into
this directory. See **[.envrc](/.envrc)** for details. The automated setup tool
also warns you about these facts.

## fully automated setup

**Experiment**: what if we used `nix run` as an "setup tool" to setup `direnv`
and `nix`'s configuration? In other words, use it to bootstrap the development
environment? And what if I wrote it in **[Rust]** to learn more of it?

Run this command from your `$HOME` (or any directory, but it won't touch the
current working dir):

```bash
nix run \
    --tarball-ttl 0 \
    --accept-flake-config \
    'github:thoughtpolice/buck2-nix?dir=buck/nix#setup'
```

This tool will set up everything to build this repository correctly, and (by
default) clone a copy of the source code for you, under `$HOME`. I hope. The
goal is that Nix along with the above command should be able to completely
bootstrap your working environment. If it doesn't work, please
[let me know](/issues). Check out the source code under
**[./buck/nix/setup/](/buck/nix/setup)**

## treading water

Assuming the setup tool worked with the default configuration to clone under
`$HOME`:

```bash
cd $HOME/buck2-nix.sl
```

This will activate `direnv` automatically &mdash; assuming nothing exploded
&mdash; and `buck --version` should now work. This early "bootstrap phase" is
intended to be as lightweight as possible, with the minimal tooling needed for
everything else to work; so only `buck` and other critical tools are installed
into your shell environment at this point.

Now, build whole repo. The build is automatically configured (via flake
configuration) to use my upstream binary cache &mdash; this is why you being a
trusted user is so strongly emphasized, so it's fully automatic &mdash; to
download all tools needed on demand.

```bash
buck build ... # equivalent to root//...
```

Much like how Nix works, in this design, Buck only commands Nix to downloads
things as they're needed; e.g. `rust-stable` will only be downloaded through
`nix build` the moment it's needed for a Buck rule, and a target using that rule
was demanded. So if you only build one component of the repository, only a small
subset of Nix paths are downloaded. This "lazy" design is a distinct difference
from a typical `direnv` setup with Nix Flakes, which are "eager" to put things
in your shell environment immediately.

And so, the very first time you run this, you'll see many Nix paths downloading
into your store from the binary cache.

Now, clean `buck-out/`, then kill the `buck2d` daemon

```bash
buck clean
```

You can finally move out of the directory, and `buck` will go away:

```bash
cd $HOME
```

<!-- refs -->

[Buck2]: https://github.com/facebook/buck2
[Sapling]: https://sapling-scm.com
[Nix]: https://nixos.org
[direnv]: https//direnv.net
[Rust]: https://rust-lang.org
