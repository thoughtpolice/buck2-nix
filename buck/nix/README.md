# nix infrastructure

**STOP NOW AND RETREAT**. This probably isn't where you want to be.

This _looks_ like a [Nix] Flake that you can use for development, i.e.
`nix shell`. It isn't. It's _part of the environment_ you use for development,
but other parts are taken care of by direnv. This isn't enough.

Don't touch the stuff in here, **UNLESS** you're adding basic tools to the
ambient shell environment, which should be lightweight.

Generally, it's expected that:

- _most_ users will be insulated from Nix, so they won't need to touch this,
- anyone who _does_ touch this will be doing it via automation, and
- any updates should kick in automatically for users

So: don't touch this. The details aren't all figured out yet.

## so what now?

upgrade things:

```bash
buck run root//buck/nix:update -- --help
```

<!-- refs -->

[Nix]: https://nixos.org
