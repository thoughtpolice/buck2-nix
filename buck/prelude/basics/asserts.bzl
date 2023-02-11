# SPDX-FileCopyrightText: © 2017 The Bazel Authors. All rights reserved.
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/asserts.bzl -- Assertion functions.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/asserts.bzl", "asserts")

"""Testing support.

This is a modified version of https://github.com/bazelbuild/bazel-skylib/blob/main/lib/unittest.bzl.
Currently, if there are any failures, these are raised immediately by calling fail(),
which trigger an analysis-time build error.
"""

## ---------------------------------------------------------------------------------------------------------------------

def _assert_equals(expected, actual, msg = None):
    """Asserts that the given `expected` and `actual` are equal.

    Args:
      expected: the expected value of some computation.
      actual: the actual value return by some computation.
      msg: An optional message that will be printed that describes the failure.
        If omitted, a default will be used.
    """
    if expected != actual:
        expectation_msg = 'Expected "%s", but got "%s"' % (expected, actual)
        if msg:
            full_msg = "%s (%s)" % (msg, expectation_msg)
        else:
            full_msg = expectation_msg
        fail(full_msg)

def _assert_true(
        condition,
        msg = "Expected condition to be true, but was false."):
    """Asserts that the given `condition` is true.

    Args:
      condition: A value that will be evaluated in a Boolean context.
      msg: An optional message that will be printed that describes the failure.
        If omitted, a default will be used.
    """
    if not condition:
        fail(msg)

def _assert_false(
        condition,
        msg = "Expected condition to be false, but was true."):
    """Asserts that the given `condition` is false.

    Args:
      condition: A value that will be evaluated in a Boolean context.
      msg: An optional message that will be printed that describes the failure.
        If omitted, a default will be used.
    """
    if condition:
        fail(msg)

## ---------------------------------------------------------------------------------------------------------------------

asserts = struct(
    equals = _assert_equals,
    true = _assert_true,
    false = _assert_false,
)
