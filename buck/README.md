# buck2 setup

This is any/all internal documentation of the Buck/Nix integration in this
repository, as well as other notes, todos, garbage, *et cetera*.

# Basic prerequisites

In the world of Buck and similar systems, the idea is to have a set of "vendor
toolchains", each one for some "build process" in your codebase &mdash; so there
is a C toolchain, Python, Rust, Haskell, but also more abstract ones: Protobuf
compilation, Babel transliteration, jinja templates, etc. These toolchains are
typically built and compiled by hand for your particular engineering
environment. There are many reasons to vendor such toolchains, but this
vendoring step is mostly assumed to be handled already

> **NOTE**: There are a lot of reasons to vendor toolchains versus using the
> ones provided by your operating system; in fact there are often good reasons
> not to support any other version than what you personally run in production.
> This document is not designed to litigate these points.

Vendor toolchains are described in Starlark, a language that is "more or less
like Python". Once a toolchain is provided, then you can also use Starlark to
describe Buck *rules*: a set of actions to produce some output from a given set
of inputs. For example, you can use the Rust toolchain to write a `build_rust`
rule, that will take Rust files as input, and produce executables as a result.

> **NOTE**: The notion of rules and targets is more or less universal across
> build systems. But, in short: a rule is a set of commands to run, while a
> target is a result that is to be built by some rule.

# Using Nix to vendor toolchains

So before we even get to writing Starlark rules for source code, to turn it into
executables &mdash; where do the toolchains come from?

Enter **[Nix]**, the universal package manager for all Linux distros (and macOS,
too)! Nix is a vendor-agnostic, language-agnostic, and Linux-distro-agnostic
system for distributing packages and software builds. Once you install it on
your distro, you can download prebuilt binary packages, and produce binary
packages, and distribute them, to any other system of your choosing (with or
without Nix!) And it can do many other things too, like produce Docker images,
produce bootable OS ISOs, run virtual machines and test whole software stacks,
*et cetera*.

Nix is also heavily battle tested, with thousands of packages, hundreds of
developers, and many hours of work put into it. It excels at tasks like the
[Reproducible Builds] effort thanks to its hermetic design, and it is constantly
being developed in the open. It's a great project. You should try it!

But while Nix is excellent at vendoring *toolchains* and large *packages*, it
isn't so good at high-efficiency, latency sensitive development loops. For
example, the story for performing incremental builds is rather poor. Rather, Nix
has largely evolved to compile things at the level of "package" granularity, and
provide toolchains that end-users (programmers) can use to do "fast" development
loops.

[Nix]: https://nixos.org
[Reproducible Builds]: https://reproducible-builds.org/

# Overview of the source

In this design, Nix is the "ground truth" and source of all our vendored
toolchains, while Buck drives these toolchains in a fast, incremental fashion
for developer workflows and the dev/build/test loop. So everything starts with
Nix, and is abstracted away from there.

In short:

- If it's a tool from an upstream source, it comes from Nix, and the description
  of the build is written in Nix. This includes compilers, linkers, linters, et
  cetera.
- If it exists and is developed in "this" repository, it's described and built
  with Buck, and its build is described with Starlark. We use the toolchains
  from Nix to build these things, typically. But we also write rules for our own
  toolchains; for example we might write a compiler, then write a set of Buck
  rules to invoke that compiler, and then use that compiler to produce more
  outputs.

This gives us a middle-ground between the two worlds; Nix and the Nixpkgs
community is used to provide vendor-agnostic, distro-agnostic, high-quality
toolchains. And Buck is used to drive those tools quickly for development.

## `./buck/nix`

Nix code. Notably, this includes a Nix Flake which locks us to a fixed `nixpkgs`
snapshot, from which all of our toolchains come from. And it also includes the
"bootstrap" build to compile Buck and provide it, among other tools.

In short, this code is used to setup vendored toolchains, but no more than that.
Software that exists "in this repository" is instead described using Starlark.

If you were to add a toolchain of some kind (e.g. "I want to support Julia
programs written in this repository"), you'd have to start by packaging that
toolchain with Nix, and put the code here.

## `./buck/prelude`

Buck rules, written in Starlark. These drive the tools that Nix provisions for
us, and does so in a fast, incremental way.

Once you have a toolchain provisioned with Nix, you can begin writing Starlark
code that end-users can then consume to build programs.
