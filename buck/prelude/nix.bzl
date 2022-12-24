# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:nix.bzl -- tools for driving Nix files and toolchains for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:nix.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

load(
  "@prelude//basics/providers.bzl",
  "NixStoreOutputInfo",
)

## ---------------------------------------------------------------------------------------------------------------------

def __mk_nix_build_cmd(ctx, hash, deps=[]):
    # [tag:bzl-nix-cell] This rule should never be instantiated anywhere other
    # than the root TARGETS file of the nix// cell. Make sure of that.
    if ctx.label.cell != "nix":
        fail("nix_drv must be used in the nix cell (was {})".format(ctx.label.cell))

    out = ctx.actions.declare_output("{}".format(hash))
    storepath = "/nix/store/{}".format(hash)
    args = cmd_args([
        "nix", "build", "--accept-flake-config",

        # see [ref:cache-url-warning]
        "--extra-substituters", "https://buck2-nix-cache.aseipp.dev/",
        "--trusted-public-keys", "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= buck2-nix-preview.aseipp.dev-1:sLpXPuuXpJdk7io25Dr5LrE9CIY1TgGQTPC79gkFj+o=",
        "--out-link", out.as_output(),
        storepath,
    ]).hidden(deps)
    ctx.actions.run(args, category = "nix")
    return [ out, storepath ]

def __nix_toolchain_0(ctx):
    deps = [ ctx.attrs.path[NixStoreOutputInfo].path ]
    [ out, storepath ] = __mk_nix_build_cmd(ctx, ctx.attrs.hash, deps)
    return [
        DefaultInfo(default_outputs = [out]),
        NixStoreOutputInfo(path = out)
    ]

def __nix_store_path_0(ctx):
    deps = [ r[NixStoreOutputInfo].path for r in ctx.attrs.refs ]
    [ out, storepath ] = __mk_nix_build_cmd(ctx, ctx.label.name, deps)
    return [
        DefaultInfo(default_outputs = [out]),
        NixStoreOutputInfo(path = out)
    ]

__nix_toolchain = rule(
    impl = __nix_toolchain_0,
    attrs = {
        "path": attrs.dep(),
        "hash": attrs.string(),
        "drv": attrs.string(),
    },
)

__nix_store_path = rule(
    impl = __nix_store_path_0,
    attrs = {
        "drv": attrs.string(),
        "refs": attrs.list(attrs.dep(), default = []),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

def interpret_toolchains(toolchains: {"string": "string"}, depgraph):
    for t, h in toolchains.items():
        drv = depgraph[h]["d"]
        __nix_toolchain(
            name = t,
            hash = h,
            path = ":{}".format(h),
            drv = drv,
            visibility = ["PUBLIC"],
        )

    for h, o in depgraph.items():
        __nix_store_path(
            name = h,
            drv = o["d"],
            refs = [ ":{}".format(r) for r in o["r"] ],
        )

## ---------------------------------------------------------------------------------------------------------------------
