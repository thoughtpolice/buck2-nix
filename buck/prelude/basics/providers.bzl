# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: Apache-2.0

# @prelude//basics/providers.bzl -- Build info providers for Buck.
#
# HOW TO USE THIS MODULE:
#
#   N/A. Providers are automatically loaded by the prelude.

"""Providers used by all Buck rules in this prelude."""

load("@prelude//basics/files.bzl", "files")
load("@prelude//toolchains/nixpkgs.bzl", "nix");
load("@prelude//toolchains/bash/main.bzl", "bash");
load("@prelude//toolchains/prolog/main.bzl", "prolog");
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

_update(files.providers)
_update(nix.providers)
_update(bash.providers)
_update(rust.providers)
_update(prolog.providers)
_update(zipfile.providers)
