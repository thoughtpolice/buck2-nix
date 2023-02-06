# nix infrastructure

**STOP NOW AND RETREAT**. This probably isn't where you want to be.

This *looks* like a [Nix] Flake that you can use for development. It isn't.

You *might* be a [Nix] user and think you know what you're doing here. You might
not, in fact.

Don't touch the stuff in here, **UNLESS** you're adding a toolchain for buck to
use, i.e. a set of tools that will be driven by Starlark. If you're doing that,
and are proficient in Nix, this is a good place to be.

Generally, it's expected that:

- *most* users will be insulated from Nix, so they won't need to touch this,
- anyone who *does* touch this will be doing it via automation, and
- any updates should kick in automatically for users

So: don't touch this. The details aren't all figured out yet.

## so what now?

upgrade things:

```bash
buck run root//buck/nix:update -- --help
```

<!-- refs -->

[Nix]: https://nixos.org
