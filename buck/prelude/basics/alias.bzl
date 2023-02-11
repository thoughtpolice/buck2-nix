# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/alias.bzl -- alias() rule.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/alias.bzl", "alias")

"""Target aliases.

Target aliases are a way to map one target to another name; this is mostly
useful when combined with `select()` in order to implement conditional
dependencies or outputs based on the platform.
"""

## ---------------------------------------------------------------------------------------------------------------------

def __alias_impl(ctx: "context") -> ["provider"]:
    return ctx.attrs.actual.providers

alias = rule(
    doc = """Alias a target to another target.""",
    impl = __alias_impl,
    attrs = { "actual": attrs.dep() },
)
