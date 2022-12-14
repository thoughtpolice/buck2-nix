# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:rust.bzl -- rust compilation.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:rust.bzl", "rust_binary")

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//basics/providers.bzl", "NixStoreOutputInfo")

## ---------------------------------------------------------------------------------------------------------------------

def __rust_binary_impl(ctx: "context") -> ["provider"]:
    file = ctx.attrs.file
    out_name = ctx.attrs.out if ctx.attrs.out else ctx.label.name
    out = ctx.actions.declare_output(out_name)

    cmd = [ cmd_args(ctx.attrs._rust_stable[NixStoreOutputInfo].path, format="{}/bin/rustc") ]
    cmd.append(["--crate-type=bin", file, "-o", out.as_output()])
    ctx.actions.run(cmd, category = "rustc")

    return [
        DefaultInfo(default_outputs = [out]),
        RunInfo(args = cmd_args([out])),
    ]

rust_binary = rule(
    impl = __rust_binary_impl,
    attrs = {
        "file": attrs.source(),
        "out": attrs.option(attrs.string(), default = None),
        "_rust_stable": attrs.default_only(attrs.dep(default = "@nix//toolchains:rust-stable")),
    },
)
