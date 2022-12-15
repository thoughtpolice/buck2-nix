# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@prelude//:nix.bzl", "nix_get_bin", "nix_toolchain_dep")

def __zip_impl(ctx):
    out_name = ctx.attrs.out if ctx.attrs.out else "{}.zip".format(ctx.label.name)
    out = ctx.actions.declare_output(out_name)

    cmd = [
        nix_get_bin(ctx.attrs._nix_zip, "zip"),
        out.as_output(),
    ]

    for s in ctx.attrs.srcs:
        cmd.append(s)

    ctx.actions.run(cmd, category = "zip")
    return [ DefaultInfo(default_outputs = [out]) ]

zip_file = rule(
    impl = __zip_impl,
    attrs = {
        "srcs": attrs.list(attrs.source(allow_directory = False), default = []),
        "out": attrs.option(attrs.string(), default = None),
        "_nix_zip": nix_toolchain_dep(":zip"),
    },
)
