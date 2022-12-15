# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@prelude//:nix.bzl", "nix_get_bin", "nix_toolchain_dep")

def __rust_binary_impl(ctx: "context") -> ["provider"]:
    file = ctx.attrs.file
    out_name = ctx.attrs.out if ctx.attrs.out else ctx.label.name
    out = ctx.actions.declare_output(out_name)

    rustc = nix_get_bin(ctx.attrs._nix_rustc, "rustc")
    cmd = cmd_args([rustc, "--crate-type=bin", file, "-o", out.as_output()])

    ctx.actions.run(cmd, category = "compile")

    return [
        DefaultInfo(default_outputs = [out]),
        RunInfo(args = cmd_args([out])),
    ]

rust_binary = rule(
    impl = __rust_binary_impl,
    attrs = {
        "file": attrs.source(),
        "out": attrs.option(attrs.string(), default = None),
        "_nix_rustc": nix_toolchain_dep(":rust-stable"),
    },
)
