# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@prelude//:nix.bzl", "nix_target", "nix_bin_path")

def __zip_impl(ctx):
    out_name = ctx.attrs.out if ctx.attrs.out else "{}.zip".format(ctx.label.name)
    out = ctx.actions.declare_output(out_name)
    srcs = ctx.attrs.srcs

    def k(ps) -> ["provider"]:
        cmd = cmd_args([
            nix_bin_path(ps, "zip"),
            out.as_output(),
        ])

        for s in srcs:
            cmd.add(s)

        ctx.actions.run(cmd, category = "zip")
        return [ DefaultInfo(default_outputs = [out]) ]

    return nix_target(ctx, "zip").map(k)

zip_file = rule(
    impl = __zip_impl,
    attrs = {
        "srcs": attrs.list(attrs.source(allow_directory = False), default = []),
        "out": attrs.option(attrs.string(), default = None),
    },
)
