# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:bash.bzl -- bash utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:bash.bzl", "run_bash")

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//:nix.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

def __bash_impl(ctx):
    out = ctx.actions.declare_output("{}.sh".format(ctx.label.name))
    ctx.actions.copy_file(out, ctx.attrs.src)

    cmd = [ nix.get_bin(ctx, ":bash", "bash") ]
    cmd.append(cmd_args(out))

    return [ DefaultInfo(default_outputs = [out]), RunInfo(args = cmd) ]

run_bash = nix.toolchain_rule(__bash_impl, [ ":bash" ], {
    "src": attrs.source(allow_directory = False),
})
