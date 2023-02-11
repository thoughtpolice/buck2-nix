# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//zip.bzl -- zip and archive files
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:zip.bzl", "zip_file")

## ---------------------------------------------------------------------------------------------------------------------

def __create_impl(ctx: "context") -> ["provider"]:
    out_name = ctx.attrs.out if ctx.attrs.out else "{}.zip".format(ctx.label.name)
    out = ctx.actions.declare_output(out_name)

    cmd = [ cmd_args(ctx.attrs._zip[DefaultInfo].default_outputs[0], format="{}/bin/zip") ]
    cmd.append(out.as_output())

    for s in ctx.attrs.srcs:
        cmd.append(s)

    ctx.actions.run(cmd, category = "zip")
    return [ DefaultInfo(default_output = out) ]

__create = rule(
    impl = __create_impl,
    attrs = {
        "srcs": attrs.list(attrs.source(allow_directory = False), default = []),
        "out": attrs.option(attrs.string(), default = None),
        "_zip": attrs.default_only(attrs.dep(default = "@prelude//toolchains/zip:zip")),
    }
)

## ---------------------------------------------------------------------------------------------------------------------

zipfile = struct(
    create = __create,

    attributes = {},
    providers = {},
)
