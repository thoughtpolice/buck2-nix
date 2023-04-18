# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/nixpkgs.bzl -- nixpkgs utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/nixpkgs.bzl", "nix")

load("@prelude//basics/files.bzl", "files")

## ---------------------------------------------------------------------------------------------------------------------

def __nix_build(ctx: "context", build_name: str.type, expr, binary: [str.type, None] = None) -> ["provider"]:
    nixpkgs = ctx.attrs._nixpkgs[DefaultInfo].default_outputs[0]

    deps = [o[DefaultInfo].default_outputs[0] for o in ctx.attrs.deps]

    overlays = []
    for (name, dep) in ctx.attrs._overlays.items():
        overlays.append((name, dep[DefaultInfo].default_outputs[0]))

    build_nix, build_nix_macros = ctx.actions.write(
        "build.nix",
        [
            "let",
            "  overlays = ["
        ] + ["    (import <{}>)".format(x[0]) for x in overlays] + [
            "  ];",
            "  config = { };",
            "in with import <buckpkgs> { inherit config overlays; }; (",
            expr,
            ") /* EOF */",
            "", # XXX: newline for readability in terminal
        ],
        is_executable = False,
        allow_args = True,
    )

    overlay_args = []
    for (name, dep) in overlays:
        overlay_args.append(cmd_args(dep, format="  -I "+name+"=file://$PWD/{} \\"))

    out_link = ctx.actions.declare_output("out.link")
    build_sh, _ = ctx.actions.write(
        "build.sh",
        cmd_args([
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "[ -f /buildbarn/profile ] && source /buildbarn/profile",
            "export NIX_PATH=",
            "nix build \\",
            "  -I buckroot=$PWD \\",
            cmd_args(nixpkgs, format="  -I buckpkgs=file://$PWD/{} \\"),
        ] + overlay_args + [
            cmd_args(build_nix, format="  -f {} \\"),
            "  --out-link \"$1\"",
            "", # XXX: newline for readability in terminal
        ]),
        is_executable = True,
        allow_args = True,
    )
    build_sh_cmd = cmd_args(build_sh).hidden(
        [ o[1] for o in overlays ] + [
            build_nix, build_nix_macros,
            nixpkgs,
            deps,
        ],
    )

    ctx.actions.run(
        cmd_args([build_sh_cmd, out_link.as_output()]),
        category = "nix_build",
        identifier = "{}.nix".format(build_name),
    )

    run_info = []
    if binary != None:
        run_info.append(
            RunInfo(
                args = cmd_args(out_link, format="{}/" + ctx.attrs.binary),
            ),
        )

    return [
        DefaultInfo(
            default_output = out_link,
            sub_targets = {
                "nix": [ DefaultInfo(default_outputs = [ build_nix ]) ],
                "builder": [ DefaultInfo(default_output = build_sh) ],
            },
        ),
    ] + run_info

__nix_attrs = {
    "_nixpkgs": attrs.default_only(attrs.dep(default = "prelude//toolchains:nixpkgs.tar.gz")),
    "_overlays": attrs.default_only(attrs.named_set(attrs.dep(), default = {
        # XXX FIXME (aseipp): [tag:add-nixpkgs-overlay] sync with BUILD file somehow?
        "overlay-rust": "prelude//toolchains:nixpkgs-overlay-rust.tar.gz",
    })),
    "deps": attrs.list(attrs.dep(), default = []),
}

__build = rule(
    impl = lambda ctx: __nix_build(ctx, ctx.label.name, ctx.attrs.expr, ctx.attrs.binary),
    attrs = __nix_attrs | {
        "expr": attrs.arg(),
        "binary": attrs.option(attrs.string(), default = None),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

def __get_toolchain(key: str.type, name: str.type, ps: ["_a"]) -> "attribute":
    name: str.type = "@prelude//toolchains/{}:{}".format(key, name)
    return attrs.toolchain_dep(default = name, providers = ps)

def __toolchain_rule(impl, attrs, **kwargs):
    return rule(
        impl = impl,
        attrs = __nix_attrs | attrs,
        is_toolchain_rule = True,
        **kwargs,
    )

def __build_file(name, src, **kwargs):
    fname = "nix-build-{}.nix".format(name)
    files.export(name = fname, src = src)
    nix.rules.build(
        name = name,
        expr = """pkgs.callPackage (<buckroot> + "/$(location :{})") {{ }}""".format(fname),
        deps = [ ":{}".format(fname) ],
        **kwargs,
    )

## ---------------------------------------------------------------------------------------------------------------------

nix = struct(
    rules = struct(
        build = __build,
        build_file = __build_file
    ),

    macros = struct(
        build = __nix_build,
        get_toolchain = __get_toolchain,
        toolchain_rule = __toolchain_rule,
    ),

    attrs = __nix_attrs,

    attributes = {},
    providers = {},
)
