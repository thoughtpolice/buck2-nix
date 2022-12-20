# buck2 nix expression

This is a Nix package to build `buck2` from [the Meta
repo](https://github.com/facebookincubator/buck2/). It has a particular update
procedure.

## how to update

```bash
$(sl root)/buck/nix/buck2/update.sh
```

> **NOTE**: The buck2 team internally does not use `Cargo.lock` files, hence why
> we have to generate our own as well; otherwise this script would simply be
> able to use `nix-update`
