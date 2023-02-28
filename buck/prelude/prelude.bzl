# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//prelude.bzl -- Global import shim.
#
# NOTE: this module is handled in a special way by Buck2; anything exported here
# by using a public symbol name is available in *all* BUILD files, available to
# use in ALL other targets! This is very powerful, and also an easy footgun.
#
# It is VERY IMPORTANT that you do not add unnecessary top-level exportable
# declarations here. The reason for this is largely pretty simple: code
# cleanliness. Import time is one thing, but even then it is much, much more
# preferable to explicitly import the symbols and rules you need directly from a
# well defined module, versus cluttering the global scope with endless rules and
# functions and macros. This just makes all code easier to read and understand.
#
# For the most part, the only thing this should *really* export is things that
# are globally useful to BUILD files in user code, as well as useful
# declarations for out-of-line `.bzl` files. (The upstream buck2-prelude itself
# uses this magic file to export all global rules and many other things, which
# is apparently considered (by them) to be an anti-feature these days, but a
# necessary one for buck1 compatibility. So this is one thing we can do better.)
#
# NOTE: the symbols exported here *are not implicitly included* in the `.bzl`
# files located inside the prelude// cell; that would be an obvious recursive
# import error, so prelude code must `load()` symbols explicitly. It is only
# `.bzl` files outside of the prelude// cell, and BUILD files, which have these
# symbols available.
#
# REMEMBER: Do not taunt Happy Fun Ball, and do not add things to this file
# unless absolutely necessary.

"""Global Buck prelude."""

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//basics/config.bzl", _config = "config")

load("@prelude//basics/pkg.bzl",
  _owner = "owner",
  _license = "license",
  _description = "description",
  _version = "version",
)

load("@prelude//basics/alias.bzl", _alias = "alias")
load("@prelude//basics/asserts.bzl", _asserts = "asserts")
load("@prelude//basics/files.bzl", _files = "files")
load("@prelude//basics/download.bzl", _download = "download")
load("@prelude//basics/paths.bzl", _paths = "paths")
load("@prelude//basics/genrule.bzl", _genrule = "genrule")

load("@prelude//basics/types.bzl",
  "attributes",
  "providers",
)

## ---------------------------------------------------------------------------------------------------------------------

# Load all attributes and providers in the default environment. This is largely
# helpful so that random one-off .bzl files have basic types available.

load_symbols(attributes)
load_symbols(providers)

## ---------------------------------------------------------------------------------------------------------------------

# Finally, export the symbols we want to be globally available, which are mostly
# a set of very primitive and/or generic rules and macros that can be used
# anywhere.

load_symbols({
    # Global symbols that are available
    "alias": _alias,
    "genrule": _genrule,

    # Package metadata
    "owner": _owner,
    "license": _license,
    "description": _description,
    "version": _version,

    # Struct-based APIs
    "asserts": _asserts,
    "config": _config,
    "download": _download,
    "files": _files,
    "paths": _paths,
})
