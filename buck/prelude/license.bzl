# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:license.bzl -- license helpers
#
# This module provides for code to use SPDX-compatible license expressions
# inside rules. It contains a valid list of all SPDX license identifiers, as
# well as a list of all SPDX license exceptions, and some APIs to work with
# them.
#
# This module is mostly internal to the prelude// cell and so it should mostly
# be transparent to _users of a rule_, beyond listing the license of their
# component using SPDX short identifiers; _rule authors_ instead can use some of
# these APIs to provide the needed attributes for rule users in a consistent
# way, so compatibility can be checked, bxl scripts can be written, etc.

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//basics/spdx.bzl", _licenses = "license_list", _exceptions = "exception_list")

## ---------------------------------------------------------------------------------------------------------------------

def parse_spdx_expr(expr: "string") -> "list":
    """Parse an SPDX license expression into a list of license identifiers."""
    fail("NIH")

def check_spdx_license(expr: "context") -> "NoneType":
    pass
