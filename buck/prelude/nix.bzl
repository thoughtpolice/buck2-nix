# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:nix.bzl -- tools for driving Nix files and toolchains for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:nix.bzl", "nix")

## ---------------------------------------------------------------------------------------------------------------------

load(":providers.bzl", "NixRealizationInfo")

# [tag:bzl-nix-toolchain] This is a very special import that should NOT be used
# anywhere else. It effectively imports a JSON representation of the Nix closure
# for our tools we want vendored, which we then use to realize outputs and
# provide tools for Buck rules. But nobody else should know about this.
#
# Note that the import for this file comes from the nix// cell, which is a
# special one that is generated automatically by update.sh. This is the only
# usage of the nix// cell, and its only import is here. See [ref:bzl-nix-cell]
#
# XXX FIXME: perform a grep/hack to check '@nix//' isn't used anywhere else?
load("@nix//:toolchains.bzl", __nix_toolchains__ = "nix_toolchains")

## ---------------------------------------------------------------------------------------------------------------------

def __nix_drv_impl(ctx: "context") -> ["provider"]:
    # [tag:bzl-nix-cell] This rule should never be instantiated anywhere other
    # than the root TARGETS file of the nix// cell. Make sure of that.
    if ctx.label.cell != "nix":
        fail("nix_drv must be used in the nix cell (was {})".format(ctx.label.cell))

    if not ctx.label.name in __nix_toolchains__:
        fail("no such nix toolchain: {}".format(ctx.label.name))

    toolchain = __nix_toolchains__[ctx.label.name]
    tcpath = ctx.actions.declare_output("toolchain.json")

    script, _ = ctx.actions.write(
        "realize.sh", [
            cmd_args(["set", "-xeu"], delimiter = " "),
            cmd_args(["nix-store", "--realise", toolchain["drv"]], delimiter = " "),
            cmd_args(["nix", "realisation", "info", "--json", toolchain["drv"], ">", tcpath.as_output()], delimiter = " "),
            cmd_args("")
        ],
        is_executable = True,
        allow_args = True,
    )
    ctx.actions.run(
        cmd_args(["/usr/bin/env", "bash", script])
            .hidden([tcpath.as_output()]),
        category = "nix",
    )

    gcrootdir = ctx.actions.declare_output("nix-toolchain/gcroots", dir = True)
    def parse_nix_realisation_info(ctx: "context", artifacts, outputs):
        info = artifacts[tcpath].read_json()
        outdir = outputs[gcrootdir]

        script_text = [ cmd_args(["mkdir", "-p", outdir], delimiter = " ") ]

        for i in info:
            attrname = i["id"][72:]
            storePath = "/nix/store/{}".format(i["outPath"])
            gcroot = "/nix/var/nix/gcroots/per-user/$USER/buck2-{}".format(i["outPath"])

            # to do an atomic rename with safety:
            #   1) link: $outDir/foo -> /nix/store/...-foo
            #   2) link: /nix/var/nix/gcroots/auto/... -> $outDir/foo
            fmt = "{}/" + attrname
            script_text.append(cmd_args(outdir, format=(" ".join(["ln", "-snfv", storePath, fmt ]))))
            script_text.append(cmd_args(outdir, format=(" ".join(["ln", "-snfv", "$(sl root)/" + fmt, gcroot ]))))
            script_text.append("")

        script, _ = ctx.actions.write(
            "link.sh",
            script_text,
            is_executable = True,
            allow_args = True,
        )

        ctx.actions.run(
            cmd_args(["/usr/bin/env", "bash", script])
                .hidden([outdir.as_output()]),
            category = "nix",
        )

    ctx.actions.dynamic_output(
        dynamic = [ tcpath ],
        inputs = [ ],
        outputs = [ gcrootdir ],
        f = parse_nix_realisation_info,
    )

    return [
        DefaultInfo(default_outputs = [ tcpath, gcrootdir ]),
        NixRealizationInfo(rootdir = gcrootdir),
    ]

## ---------------------------------------------------------------------------------------------------------------------

def __nix_get_bin(ctx: "context", toolchain: "string", bin: "string"):
    k = "_nix_" + toolchain
    dep = getattr(ctx.attrs, k)
    return cmd_args(dep[NixRealizationInfo].rootdir, format = "{}/out/bin/" + bin)

def __nix_toolchain_dep(name: "string"):
    return attrs.default_only(attrs.dep(default = "nix//{}".format(name)))

def __nix_toolchain_deps(names: "list", attrs: "dict") -> "dict":
    rs = {}
    for name in names:
        k = "_nix_" + name
        rs[k] = __nix_toolchain_dep(name)
    return rs | attrs

def __nix_toolchain_rule(impl, deps: "list", attrs: "dict") -> "rule":
    return rule(
        impl = impl,
        attrs = __nix_toolchain_deps(deps, attrs),
    )

## ---------------------------------------------------------------------------------------------------------------------

# This rule yields a Provider that points and output /nix/store paths.
nix_toolchain = rule(
    impl = __nix_drv_impl,
    attrs = {},
)

# A struct containing the exported API.
nix = struct(
    toolchain_rule = __nix_toolchain_rule,
    get_bin = __nix_get_bin,
)
