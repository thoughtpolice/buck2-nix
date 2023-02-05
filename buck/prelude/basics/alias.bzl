# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:bash.bzl -- bash utilities
#
# HOW TO USE THIS MODULE:
#
# XXX FIXME (aseipp): describe

## ---------------------------------------------------------------------------------------------------------------------

def __alias_impl(ctx: "context") -> ["provider"]:
    return ctx.attrs.actual.providers

alias = rule(
    impl = __alias_impl,
    attrs = { "actual": attrs.dep() },
)
