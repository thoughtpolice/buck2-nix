# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: Apache-2.0

# @prelude//basics/types.bzl -- Global types for Buck rules.
#
# HOW TO USE THIS MODULE:
#
#   N/A. Providers are automatically loaded by the prelude.

"""Providers used by all Buck rules in this prelude."""

load("@prelude//basics/files.bzl", "files")
load("@prelude//toolchains/nixpkgs.bzl", "nix");
load("@prelude//toolchains/bash/main.bzl", "bash");
load("@prelude//toolchains/cxx/main.bzl", "cxx");
load("@prelude//toolchains/prolog/main.bzl", "prolog");
load("@prelude//toolchains/rust/main.bzl", "rust");
load("@prelude//toolchains/zip/main.bzl", "zipfile");

## ---------------------------------------------------------------------------------------------------------------------

# Global attributes. Key->value pairs of attribute names and their types.
attributes = { }

# Global providers. Key->value pairs of provider names and their types.
providers: {str.type: "provider"} = { }

## ---------------------------------------------------------------------------------------------------------------------

_ALL_MODULES = [
    files,
    nix,
    bash,
    cxx,
    prolog,
    rust,
    zipfile,
]

## ---------------------------------------------------------------------------------------------------------------------

for mod in _ALL_MODULES:
    provs = getattr(mod, "providers")
    for (k, v) in provs.items():
        if k in providers:
            fail("Provider '{}' already exists!".format(k))
        providers[k] = v

    attrs = getattr(mod, "attributes")
    for (k, v) in attrs.items():
        if k in attributes:
            fail("Attribute '{}' already exists!".format(k))
        attributes[k] = v
