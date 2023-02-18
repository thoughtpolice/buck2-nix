# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/bash/main.bzl -- bash utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/bash/main.bzl", "bash")

"""Bash toolchain."""

load("@prelude//basics/files.bzl", "files")

## ---------------------------------------------------------------------------------------------------------------------

def __run_impl(ctx: "context") -> ["provider"]:
    cmd = [ cmd_args(ctx.attrs._sh[DefaultInfo].default_outputs[0], format="{}/bin/osh") ]
    cmd.append(ctx.attrs.args)

    return [ DefaultInfo(), RunInfo(args = cmd) ]

__run_rule = rule(
    doc = """Run a bash script (EXPERIMENTAL: uses the Oil interpreter)""",
    impl = __run_impl,
    attrs = {
        "args": attrs.list(attrs.arg()),
        "_sh": attrs.default_only(attrs.dep(default = "@prelude//toolchains/bash:oil")),
    },
)

def __run(name, src):
    files.export(name = src)
    return __run_rule(name = name, args = [ "$(location :{})".format(src) ])

## ---------------------------------------------------------------------------------------------------------------------

bash = struct(
    run = __run,

    attributes = {},
    providers = {},
)
