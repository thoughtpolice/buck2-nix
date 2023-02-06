# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//toolchains/nixpkgs.bzl -- nixpkgs utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//toolchains/nixpkgs.bzl", "...")


## ---------------------------------------------------------------------------------------------------------------------

def _nix_build(ctx: "context"):
    nixpkgs = ctx.attrs._nixpkgs[DefaultInfo].default_outputs[0]
    overlays = [o[DefaultInfo].default_outputs[0] for o in ctx.attrs._overlays]

    overlay_list = []
    for o in overlays:
        overlay_list.append(cmd_args(o, format="  (import (buckroot \"{}\"))"))

    overlays_nix, _ = ctx.actions.write(
        "overlays.nix",
        [
            "{ buckroot }:\n\n[",
        ] + overlay_list + [
            "]\n", # XXX: newline for readability in terminal
        ],
        is_executable = False,
        allow_args = True,
    )

    build_nix, _ = ctx.actions.write(
        "build.nix",
        [
            "let",
            "  buckroot = p: <buckroot> + (\"/\" + p);",
            cmd_args(overlays_nix, format="  overlays = import (buckroot \"{}\") { inherit buckroot; };"),
            "  config = { };",
            "in",
            cmd_args(nixpkgs, format="with import (buckroot \"{}\")"),
            "{ inherit config overlays; };",
            "  (",
            "    " + ctx.attrs.expr,
            "  )",
            "", # XXX: newline for readability in terminal
        ],
        is_executable = False,
        allow_args = True,
    )

    out_link = ctx.actions.declare_output("out.link")
    build_sh, _ = ctx.actions.write(
        "build.sh",
        cmd_args([
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            "nix build -I buckroot=\"$(buck root -k project)\" \\",
            cmd_args(build_nix, format="  -f {} \\"),
            "  --out-link \"$1\"",
            "", # XXX: newline for readability in terminal
        ]),
        is_executable = True,
        allow_args = True,
    )
    build_sh_cmd = cmd_args(build_sh).hidden(
        overlays + [
            overlays_nix, build_nix, nixpkgs
        ],
    )

    ctx.actions.run(
        cmd_args([build_sh_cmd, out_link.as_output()]),
        category = "nix_build",
        identifier = "{}.nix".format(ctx.label.name),
    )

    run_info = []
    if ctx.attrs.binary != None:
        run_info.append(
            RunInfo(
                args = cmd_args(out_link, format="{}/" + ctx.attrs.binary),
            ),
        )

    return [
        DefaultInfo(
            default_output = out_link,
            sub_targets = {
                "nix": [ DefaultInfo(default_outputs = [ overlays_nix, build_nix ]) ],
                "builder": [ DefaultInfo(default_output = build_sh) ],
            },
        ),
    ] + run_info

__build = rule(
    impl = _nix_build,
    attrs = {
        "expr": attrs.string(),
        "binary": attrs.option(attrs.string(), default = None),
        "_nixpkgs": attrs.default_only(attrs.dep(default = "prelude//toolchains:nixpkgs-src")),
        "_overlays": attrs.default_only(attrs.list(attrs.dep(), default = [
            "prelude//toolchains:rust-overlay-src",
        ])),
    },
)

nix = struct(
    build = __build,

    providers = {},
)
