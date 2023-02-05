## ---------------------------------------------------------------------------------------------------------------------

load("@prelude//nixpkgs.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

def __toolchain(
        name: str.type,
        channel: str.type,
        version: str.type,
        extensions: [str.type] = [],
        targets: [str.type] = [],
    ):

    attr = "pkgs.rust-bin.{}.\"{}\"".format(channel, version)
    expr = "{}.default".format(attr)

    if extensions != [] or targets != []:
        extensions = [ "\"{}\"".format(ext) for ext in extensions ]
        targets = [ "\"{}\"".format(target) for target in targets ]

        expr = """{}.default.override {{
            extensions = [ {} ];
            targets = [ {} ];
        }}""".format(attr, " ".join(extensions), " ".join(targets))

    return nix.build(
        name = "rust-{}-{}".format(channel, name),
        expr = expr,
        visibility = [ "root//..." ],
    )

## ---------------------------------------------------------------------------------------------------------------------

def __binary_impl(ctx: "context") -> ["provider"]:
    out = ctx.actions.declare_output(ctx.attrs.out if ctx.attrs.out else ctx.label.name)

    cmd = [
        cmd_args(ctx.attrs.toolchain[DefaultInfo].default_outputs[0], format="{}/bin/rustc"),
    ]
    cmd.append(["--crate-type=bin", ctx.attrs.file, "-o", out.as_output()])
    ctx.actions.run(cmd, category = "rustc", identifier = ctx.attrs.file.basename)

    return [
        DefaultInfo(default_output = out),
        RunInfo(args = cmd_args([out])),
    ]

__binary = rule(
    impl = __binary_impl,
    attrs = {
        "file": attrs.source(),
        "out": attrs.option(attrs.string(), default = None),
        "toolchain": attrs.dep(default = "@prelude//toolchains/rust:rust-stable-stock"),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

rust = struct(
    toolchain = __toolchain,
    binary = __binary,

    providers = {}
)
