# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under both the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree and the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree.

def __rust_binary_impl(ctx: "context") -> ["provider"]:
    file = ctx.attrs.file
    out_name = ctx.attrs.out if ctx.attrs.out else ctx.label.name
    out = ctx.actions.declare_output(out_name)

    cmd = cmd_args(["rustc", "--crate-type=bin", file, "-o", out.as_output()])

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
    },
)
