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

load(
  "@prelude//platforms/defs.bzl",
  "host_config",
)

## ---------------------------------------------------------------------------------------------------------------------

def __execution_platform_nix_name(ctx) -> str.type:
    config_info = ctx.attrs._platform_info[ExecutionPlatformInfo].configuration
    constraints = config_info.constraints
    arch = None
    os = None

    for k, v in constraints.items():
        if k.name == "cpu": arch = v
        if k.name == "os":  os = v

    if arch == None or os == None:
        fail("could not determine architecture and/or OS")

    return "{}-{}".format(arch.label.name, os.label.name)

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
        "drv": attrs.option(attrs.string(), default = None),
        "_platform_info": attrs.default_only(attrs.dep(default = "@prelude//platforms:default")),
    },
)

__nix_store_path = rule(
    impl = __nix_store_path_0,
    attrs = {
        "drv": attrs.option(attrs.string(), default = None),
        "refs": attrs.list(attrs.dep(), default = []),
        "_platform_info": attrs.default_only(attrs.dep(default = "@prelude//platforms:default")),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

def interpret_toolchains(_toolchains, _depgraph):
    nix_system = host_config.nix_system.replace("-", "_") # fix name for struct
    toolchains = getattr(_toolchains, nix_system)
    depgraph = getattr(_depgraph, nix_system)

    for t, h in toolchains.items():
        __nix_toolchain(
            name = t,
            hash = h,
            path = ":{}".format(h),
            drv = depgraph[h].get("d", None),
            visibility = [ "PUBLIC" ],
        )

    for h, o in depgraph.items():
        __nix_store_path(
            name = h,
            drv = o.get("d", None),
            refs = [ ":{}".format(r) for r in o["r"] ],
        )

## ---------------------------------------------------------------------------------------------------------------------
