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
  "@prelude//platform/defs.bzl",
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

## ---------------------------------------------------------------------------------------------------------------------

def __nix_build_store_path(ctx, hash, deps=[]):
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
    ctx.actions.run(args, category = "nix_build", identifier = hash)
    return [ out, storepath ]

def __nix_eval_drv(ctx, name, deps=[]):
    system = __execution_platform_nix_name(ctx)

    out_drv = ctx.actions.declare_output("{}.nix".format(name))
    ctx.actions.write_file(out_drv, """derivation {
      name = "{name}";
      system = "{system}";
      builder = {builder};
      extra = {extra};
      args = {args};
    }""".format(
        name="cc",
        system=system,
        builder="\"${{pkgs.stdenv}}/bin/cc\"",
        extra="[]",
        args="[]",
    ))

    out_link = ctx.actions.declare_output("{}.link".format(name))
    args = cmd_args([
        "nix", "eval", "--accept-flake-config",

        # see [ref:cache-url-warning]
        "--extra-substituters", "https://buck2-nix-cache.aseipp.dev/",
        "--trusted-public-keys", "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= buck2-nix-preview.aseipp.dev-1:sLpXPuuXpJdk7io25Dr5LrE9CIY1TgGQTPC79gkFj+o=",
        "--out-link", out_link.as_output(),
        "--file", out_drv.as_output(),
    ]).hidden(deps)

    ctx.actions.run(args, category = "nix_eval", identifier = name)
    return [ out_drv, out_link ]

## ---------------------------------------------------------------------------------------------------------------------

def __nix_toolchain_0(ctx):
    deps = [ ctx.attrs.path[NixStoreOutputInfo].path ]
    [ out, _ ] = __nix_build_store_path(ctx, ctx.attrs.hash, deps)
    return [
        DefaultInfo(default_output = out),
        NixStoreOutputInfo(path = out)
    ]

def __nix_store_path_0(ctx):
    deps = [ r[NixStoreOutputInfo].path for r in ctx.attrs.refs ]
    [ out, _ ] = __nix_build_store_path(ctx, ctx.label.name, deps)
    return [
        DefaultInfo(default_output = out),
        NixStoreOutputInfo(path = out)
    ]

__nix_toolchain = rule(
    impl = __nix_toolchain_0,
    attrs = {
        "path": attrs.dep(),
        "hash": attrs.string(),
        "drv": attrs.option(attrs.string(), default = None),
        "_platform_info": attrs.default_only(attrs.dep(default = "@prelude//platform:default")),
    },
)

__nix_store_path = rule(
    impl = __nix_store_path_0,
    attrs = {
        "drv": attrs.option(attrs.string(), default = None),
        "refs": attrs.list(attrs.dep(), default = []),
        "_platform_info": attrs.default_only(attrs.dep(default = "@prelude//platform:default")),
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
