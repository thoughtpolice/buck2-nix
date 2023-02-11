# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: Apache-2.0

# @prelude//:providers.bzl -- Build info providers for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:providers.bzl", ...)

load("@prelude//nixpkgs.bzl", "nix");
load("@prelude//toolchains/bash/main.bzl", "bash");
load("@prelude//toolchains/rust/main.bzl", "rust");
load("@prelude//toolchains/zip/main.bzl", "zipfile");

## ---------------------------------------------------------------------------------------------------------------------

providers: {str.type: "provider"} = { }

def _update(ps):
    """Update the providers dict with the given provider value, exported from a toolchain."""
    for (k, v) in ps.items():
        if k in providers:
            fail("Provider '{}' already exists!".format(k))
        providers[k] = v

_update(nix.providers)
_update(bash.providers)
_update(rust.providers)
_update(zipfile.providers)
