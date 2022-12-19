# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:bash.bzl -- bash utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:bash.bzl", "run_bash")

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//basics/providers.bzl", "NixStoreOutputInfo")
load("@prelude//:nix.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

def __run_bash_impl(ctx):
    out = ctx.actions.declare_output("{}.sh".format(ctx.label.name))
    result = ctx.actions.copy_file(out, ctx.attrs.src)

    cmd = [ cmd_args(ctx.attrs._bash[NixStoreOutputInfo].path, format="{}/bin/bash") ]
    cmd.append(result)

    return [ DefaultInfo(default_outputs = [out]), RunInfo(args = cmd) ]

run_bash = rule(
    impl = __run_bash_impl,
    attrs = {
        "src": attrs.source(allow_directory = False),
        "_bash": attrs.default_only(attrs.dep(default = "@nix//toolchains:bash")),
    },
)
