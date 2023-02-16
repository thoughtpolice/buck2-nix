# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/attributes.bzl -- Global attributes.
#
# HOW TO USE THIS MODULE:
#
#    N/A. Attributes are automatically loaded by the prelude.

"""Attributes used by all Buck rules in this prelude."""

load("@prelude//basics/files.bzl", "files")
load("@prelude//toolchains/nixpkgs.bzl", "nix");
load("@prelude//toolchains/bash/main.bzl", "bash");
load("@prelude//toolchains/prolog/main.bzl", "prolog");
load("@prelude//toolchains/rust/main.bzl", "rust");
load("@prelude//toolchains/zip/main.bzl", "zipfile");

## ---------------------------------------------------------------------------------------------------------------------

attributes = { }

def _update(ps):
    """Update the attributes dict with the given attribute value, exported from a file."""
    for (k, v) in ps.items():
        if k in attributes:
            fail("Provider '{}' already exists!".format(k))
        attributes[k] = v

_update(files.attributes)
_update(nix.attributes)
_update(bash.attributes)
_update(rust.attributes)
_update(prolog.attributes)
_update(zipfile.attributes)
