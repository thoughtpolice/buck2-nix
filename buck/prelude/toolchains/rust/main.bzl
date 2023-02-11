# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/rust/main.bzl -- rust toolchain
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/rust/main.bzl", "rust")

"""Rust toolchain."""

## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//toolchains/nixpkgs.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

__toolchain_attrs = {
    "compiler": None,
    "rustdoc": None,
}

RustToolchainInfo = provider(fields = __toolchain_attrs.keys())
RustPlatformInfo = provider(fields = [ "name" ])

## ---------------------------------------------------------------------------------------------------------------------

def ctx2toolchain(ctx: "context") -> "RustToolchainInfo":
    info = ctx.attrs._toolchain[RustToolchainInfo]
    attrs = dict()
    for k, default in __toolchain_attrs.items():
        v = getattr(info, k, default)
        attrs[k] = default if v == None else v
    return RustToolchainInfo(**attrs)

## ---------------------------------------------------------------------------------------------------------------------

def __toolchain_impl(ctx: "context") -> ["provider"]:
    name = ctx.label.name
    channel = ctx.attrs.channel
    version = ctx.attrs.version
    extensions = ctx.attrs.extensions
    targets = ctx.attrs.targets

    attr = "pkgs.rust-bin.{}.\"{}\"".format(channel, version)
    expr = "{}.default".format(attr)

    if extensions != [] or targets != []:
        extensions = [ "\"{}\"".format(ext) for ext in extensions ]
        targets = [ "\"{}\"".format(target) for target in targets ]

        expr = """{}.default.override {{
            extensions = [ {} ];
            targets = [ {} ];
        }}""".format(attr, " ".join(extensions), " ".join(targets))

    ps = nix.macros.build(ctx, "rust-{}-{}".format(channel, name), expr)
    return (ps + [
        RustToolchainInfo(
            compiler = cmd_args(ps[0].default_outputs[0], format="{}/bin/rustc"),
            rustdoc = cmd_args(ps[0].default_outputs[0], format="{}/bin/rustdoc"),
        ),
        #RustPlatformInfo(), # XXX FIXME (aseipp): ???
    ])

__toolchain = rule(
    impl = __toolchain_impl,
    attrs = nix.attrs | {
        "channel": attrs.string(default = "stable"),
        "version": attrs.string(),
        "extensions": attrs.list(attrs.string(), default = []),
        "targets": attrs.list(attrs.string(), default = []),
    },
    is_toolchain_rule = True,
)

## ---------------------------------------------------------------------------------------------------------------------

def __binary_impl(ctx: "context") -> ["provider"]:
    out = ctx.actions.declare_output(ctx.attrs.out if ctx.attrs.out else ctx.label.name)

    toolchain = ctx2toolchain(ctx)
    cmd = [ toolchain.compiler ]
    cmd.append(["--crate-type=bin", ctx.attrs.file, "-o", out.as_output()])
    ctx.actions.run(cmd, category = "rustc", identifier = ctx.attrs.file.basename)

    return [
        DefaultInfo(default_output = out),
        RunInfo(args = cmd_args([out])),
    ]

__binary = rule(
    doc = """Build a rust binary.""",
    impl = __binary_impl,
    attrs = {
        "file": attrs.source(),
        "out": attrs.option(attrs.string(), default = None),
        "_toolchain": nix.macros.get_toolchain('rust', 'rust-stable', [ RustToolchainInfo ]),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

rust = struct(
    toolchain = __toolchain,
    binary = __binary,

    providers = {
        "RustToolchainInfo": RustToolchainInfo,
        "RustPlatformInfo": RustPlatformInfo,
    }
)
