# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/bash/main.bzl -- bash utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/bash/main.bzl", "bash")

"""Bash toolchain."""

## ---------------------------------------------------------------------------------------------------------------------

def __run_impl(ctx: "context") -> ["provider"]:
    cmd = [
        cmd_args(ctx.attrs._sh[DefaultInfo].default_outputs[0], format="{}/bin/osh"),
        ctx.attrs.src
    ]

    return [ DefaultInfo(), RunInfo(args = cmd) ]

__run = rule(
    impl = __run_impl,
    attrs = {
        "src": attrs.source(allow_directory = False),
        "_sh": attrs.default_only(attrs.dep(default = "@prelude//toolchains/bash:oil")),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

bash = struct(
    run = __run,

    providers = {},
)
