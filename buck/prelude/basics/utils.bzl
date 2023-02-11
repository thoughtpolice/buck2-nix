# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/utils.bzl -- General utilities shared over the codebase.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/utils.bzl", "utils")

"""Miscellaneous utilities."""

## ---------------------------------------------------------------------------------------------------------------------

def _value_or(x: [None, "_a"], default: "_a") -> "_a":
    """Return the value of `x` if it's not None, otherwise return `default`."""
    return default if x == None else x

def _flatten(xss: [["_a"]]) -> ["_a"]:
    """Flatten a list of lists into a list."""
    return [x for xs in xss for x in xs]

def _flatten_dict(xss: [{"_a": "_b"}]) -> {"_a": "_b"}:
    """Flatten a list of dicts into a dict."""
    return {k: v for xs in xss for k, v in xs.items()}

## ---------------------------------------------------------------------------------------------------------------------

utils = struct(
    value_or = _value_or,
    flatten = _flatten,
    flatten_dict = _flatten_dict,
)
