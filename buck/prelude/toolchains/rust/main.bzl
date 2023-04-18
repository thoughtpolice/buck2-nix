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
    "rustdoc": None,
}

RustToolchainInfo = provider(fields = __toolchain_attrs.keys())
RustPlatformInfo = provider(fields = [ "name" ])

def ctx2toolchain(ctx: "context") -> "RustToolchainInfo":
    info = ctx.attrs._toolchain[RustToolchainInfo]
    attrs = dict()
    for k, default in __toolchain_attrs.items():
        v = getattr(info, k, default)
        attrs[k] = default if v == None else v
    return RustToolchainInfo(**attrs)

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

    ps = nix.macros.build(ctx, name, expr)
    return (ps + [
        RustToolchainInfo(
            compiler = cmd_args(ps[0].default_outputs[0], format="{}/bin/rustc"),
            rustdoc = cmd_args(ps[0].default_outputs[0], format="{}/bin/rustdoc"),
        ),
        #RustPlatformInfo(), # XXX FIXME (aseipp): ???
    ])

__toolchain = nix.macros.toolchain_rule(
    impl = __toolchain_impl,
    attrs = {
        "channel": attrs.string(default = "stable"),
        "version": attrs.string(),
        "extensions": attrs.list(attrs.string(), default = []),
        "targets": attrs.list(attrs.string(), default = []),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

def __binary_impl(ctx: "context") -> ["provider"]:
    toolchain = ctx2toolchain(ctx)
    name = ctx.attrs.out if ctx.attrs.out else ctx.label.name
    identifier = ctx.attrs.file.basename

    build_out = ctx.actions.declare_output("{}.exe".format(name))
    build_cmd = [ toolchain.compiler ]
    build_cmd.append(["--crate-type=bin", ctx.attrs.file, "-o", build_out.as_output()])
    ctx.actions.run(build_cmd, category = "rustc", identifier = identifier)

    test_out = ctx.actions.declare_output("{}.test.exe".format(name))
    test_build_cmd = [ toolchain.compiler ]
    test_build_cmd.append(["--test", ctx.attrs.file, "-o", test_out.as_output()])
    ctx.actions.run(test_build_cmd, category = "rustc", identifier = "test-{}".format(identifier))

    exe = cmd_args(build_out)
    test_exe = cmd_args(test_out)

    return [
        DefaultInfo(
            default_output = build_out,
            sub_targets = {
                "test": [ DefaultInfo(default_output = test_out) ],
            }
        ),

        RunInfo(args = [ exe ]),

        ExternalRunnerTestInfo(
            type = "rustc-test",
            command = [ test_exe ],
        ),
    ]

__rust_binary = pkg.rule_with_metadata(
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

    binary = pkg.rule_apply_metadata(__rust_binary),

    attributes = {},
    providers = {
        "RustToolchainInfo": RustToolchainInfo,
        "RustPlatformInfo": RustPlatformInfo,
    },
)
