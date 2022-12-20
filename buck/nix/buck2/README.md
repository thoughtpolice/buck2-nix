# buck2 nix expression

This is a Nix package to build `buck2` from [the Meta
repo](https://github.com/facebookincubator/buck2/). It has a simple, but
particular update procedure that can't use `nix-update` or anything else.

## how to update

```bash
buck run nix//:update -- --buck2
```

Source code is in `update.sh` in this directory.
