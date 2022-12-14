# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@root//buck/nix/toolchains.bzl", __nix_toolchains__ = "nix_toolchains")

NixRealizationInfo = provider(fields = [ "storepath", "gcroot" ])

def __nix_drv_impl(ctx: "context") -> ["provider"]:
    cell = ctx.label.cell
    name = ctx.label.name
    if not name in __nix_toolchains__:
        fail("no such nix toolchain: {}".format(name))

    toolchain = __nix_toolchains__[name]
    gcroot = ctx.actions.declare_output("nixgcroot-{}".format(name))

    cmd = cmd_args([
        "nix-store",
        "--add-root",
        gcroot.as_output(),
        "-r",
        toolchain["drv"]
    ])

    ctx.actions.run(cmd, category = "nix")
    return [
        DefaultInfo(default_outputs = [gcroot]),
        NixRealizationInfo(
            storepath = toolchain["out"],
            gcroot = gcroot,
        )
    ]

nix_drv = rule(
    impl = __nix_drv_impl,
    attrs = {},
)

# -----------------------------------------------------------------------------------------------

def nix_bin_path(ps, bin: "string") -> "string":
    return "{}/bin/{}".format(ps[NixRealizationInfo].storepath, bin)

def nix_target(ctx: "context", name: "string"):
    return ctx.actions.anon_target(nix_drv, { "name": "nix//:{}".format(name) })
