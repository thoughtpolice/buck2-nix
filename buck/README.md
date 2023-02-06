# buck2 setup

This is any/all internal documentation of the Buck/Nix integration in this
repository, as well as other notes, todos, garbage, *et cetera*.

## `./nix`

Nix code. Notably, this contains the fixed "ambient" environment snapshot (via
Nix Flakes), from which all of our basic tools are provided &mdash; -- such as
the "bootstrap" build of the Buck2 binary (called `buck`), among other tools.

In short, this code is used to setup our needed global shell environment for
building, but no more than that.

If you were to add a toolchain of some kind (e.g. "I want to support Julia
programs written in this repository"), you should be looking in the `./prelude`
subdirectory instead.

## `./prelude`

Buck rules, written in Starlark, and code to drive Nix from Starlark. These
definitions allow you to run Nix and the results of Nix derivations (e.g.
toolchains) in a fast and reliable way.

Once you have a toolchain defined in Starlark (perhaps with some helper Nix
code), you can begin writing Starlark code that end-users can then consume to
build programs or tools.
