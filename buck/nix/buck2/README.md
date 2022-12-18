# buck2 nix expression

This is a Nix package to build `buck2` from [the Meta
repo](https://github.com/facebookincubator/buck2/). It has a particular update
procedure.

## how to update

Clone or update a copy of buck2, and run `cargo build --bin=buck2 --release`.
This generates a `Cargo.lock` file; the buck2 team internally does not use
`Cargo.lock` files, hence why we have to generate our own by running the build
that way.

Then, just move the `Cargo.lock` here, and update `default.nix` in the normal
way.
