# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/utils.bzl -- General utilities shared over the codebase.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/utils.bzl", "utils")

## ---------------------------------------------------------------------------------------------------------------------

def _value_or(x: [None, "_a"], default: "_a") -> "_a":
    return default if x == None else x

# Flatten a list of lists into a list
def _flatten(xss: [["_a"]]) -> ["_a"]:
    return [x for xs in xss for x in xs]

# Flatten a list of dicts into a dict
def _flatten_dict(xss: [{"_a": "_b"}]) -> {"_a": "_b"}:
    return {k: v for xs in xss for k, v in xs.items()}

## ---------------------------------------------------------------------------------------------------------------------

utils = struct(
    value_or = _value_or,
    flatten = _flatten,
    flatten_dict = _flatten_dict,
)
