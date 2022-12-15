# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:zip.bzl -- zip and archive files
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:zip.bzl", "zip_file")

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//:nix.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

def __zip_impl(ctx):
    out_name = ctx.attrs.out if ctx.attrs.out else "{}.zip".format(ctx.label.name)
    out = ctx.actions.declare_output(out_name)

    cmd = nix.get_bin(ctx, ":zip", "zip")
    cmd.append(out.as_output())

    for s in ctx.attrs.srcs:
        cmd.append(s)

    ctx.actions.run(cmd, category = "zip")
    return [ DefaultInfo(default_outputs = [out]) ]

zip_file = nix.toolchain_rule(__zip_impl, [ ":zip" ], {
    "srcs": attrs.list(attrs.source(allow_directory = False), default = []),
    "out": attrs.option(attrs.string(), default = None),
})
