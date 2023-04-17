# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/rust/main.bzl -- rust toolchain
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/rust/main.bzl", "rust")

"""Rust toolchain."""

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//basics/pkg.bzl", "pkg")
load("@prelude//toolchains/nixpkgs.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

__toolchain_attrs = {
    "compiler": None,
}

CxxToolchainInfo = provider(fields = __toolchain_attrs.keys())
CxxPlatformInfo = provider(fields = [ "name" ])

def ctx2toolchain(ctx: "context") -> "CxxToolchainInfo":
    info = ctx.attrs.toolchain[CxxToolchainInfo]
    attrs = dict()
    for k, default in __toolchain_attrs.items():
        v = getattr(info, k, default)
        attrs[k] = default if v == None else v
    return CxxToolchainInfo(**attrs)

def __clang_toolchain_impl(ctx: "context") -> ["provider"]:
    name = ctx.label.name
    version = ctx.attrs.version
    pkg = ctx.attrs.pkg
    binary = ctx.attrs.binary

    if pkg != None:
        expr = "pkgs.{}".format(pkg)
    else:
        expr = "pkgs.clang_{}".format(version)

    binary_name = "clang" if binary == None else binary

    ps = nix.macros.build(ctx, "{}-{}".format(name, version), expr)
    return (ps + [
        CxxToolchainInfo(
            compiler = cmd_args(ps[0].default_outputs[0], format="{}/bin/"+binary_name),
        ),
    ])

__clang_toolchain = nix.macros.toolchain_rule(
    impl = __clang_toolchain_impl,
    attrs = {
        "version": attrs.string(),
        "pkg": attrs.option(attrs.string(), default = None),
        "binary": attrs.option(attrs.string(), default = None),
    },
)

def __binary_impl(ctx: "context") -> ["provider"]:
    toolchain = ctx2toolchain(ctx)
    name = ctx.attrs.out if ctx.attrs.out else ctx.label.name
    identifier = name

    sources = ctx.attrs.sources
    headers = ctx.attrs.headers
    defines = ctx.attrs.defines
    cflags = ctx.attrs.cflags

    objs = []

    for src in sources:
        ident = "{}-{}".format(identifier, src.basename)
        obj_out = ctx.actions.declare_output("{}.o".format(src.basename))
        build_cmd = [ toolchain.compiler ]
        build_cmd.append(cflags)
        build_cmd.append(["-c", src, "-o", obj_out.as_output()])
        ctx.actions.run(build_cmd, category = "cxx_cc", identifier = ident)
        objs.append(obj_out)

    exe_out = ctx.actions.declare_output("{}.exe".format(name))
    build_cmd = [ toolchain.compiler ]
    build_cmd.append([ "-o", exe_out.as_output() ])
    build_cmd.append(objs)
    ctx.actions.run(build_cmd, category = "cxx_ld", identifier = identifier)

    return [
        DefaultInfo(
            default_output = exe_out,
            sub_targets = {
                "objs": [
                    DefaultInfo(default_outputs = objs),
                ],
            },
        ),

        RunInfo(args = [ exe_out ]),
    ]

__cxx_binary = pkg.rule_with_metadata(
    doc = """Build a C/C++ binary.""",
    impl = __binary_impl,
    attrs = {
        "sources": attrs.list(attrs.source(), default = []),
        "headers": attrs.list(attrs.source(), default = []),
        "defines": attrs.list(attrs.string(), default = []),
        "cflags": attrs.list(attrs.string(), default = []),
        "out": attrs.option(attrs.string(), default = None),
        "toolchain": nix.macros.get_toolchain('cxx', 'clang-stable', [ CxxToolchainInfo ]),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

cxx = struct(
    clang_toolchain = __clang_toolchain,
    binary = pkg.rule_apply_metadata(__cxx_binary),

    attributes = {},
    providers = {
        "CxxToolchainInfo": CxxToolchainInfo,
        "CxxPlatformInfo": CxxPlatformInfo,
    },
)
