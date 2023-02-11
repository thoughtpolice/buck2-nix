# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/prolog/main.bzl -- prolog toolchain
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/prolog/main.bzl", "prolog")

"""Scryer Prolog toolchain."""

## ---------------------------------------------------------------------------------------------------------------------

def __scryer_program_impl(ctx: "context") -> ["provider"]:
    default_start_name = "{}.pro".format(ctx.label.name)
    entrypoint = ctx.attrs.start
    if entrypoint == None:
        for s in ctx.attrs.srcs:
            if s.basename == default_start_name:
                entrypoint = s
                break

    if entrypoint == None:
        fail(
            """No entrypoint file for scryer program '{}'; expected either 'start'
             attribute to be set, or '{}' to be a source file""".format(ctx.label.name, default_start_name))

    cmd = [
        cmd_args(ctx.attrs._scryer[DefaultInfo].default_outputs[0], format="{}/bin/scryer-prolog"),
        "-g", "main,halt",
        entrypoint,
        "--",
    ] + ctx.attrs.args

    return [ DefaultInfo(), RunInfo(args = cmd) ]

__scryer_program = rule(
    impl = __scryer_program_impl,
    attrs = {
        "srcs": attrs.list(attrs.source()),
        "start": attrs.option(attrs.source(), default = None),
        "args": attrs.list(attrs.arg(), default = []),
        "_scryer": attrs.default_only(attrs.dep(default = "@prelude//toolchains/prolog:scryer")),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

prolog = struct(
    scryer_program = __scryer_program,

    attributes = {},
    providers = {},
)
