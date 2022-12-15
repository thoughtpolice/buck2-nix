# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@nix//:toolchains.bzl", __nix_toolchains__ = "nix_toolchains")

NixRealizationInfo = provider(fields = [ "rootdir" ])

def __nix_drv_impl(ctx: "context") -> ["provider"]:
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
            gcroot = "/nix/var/nix/gcroots/per-user/$USER/{}".format(i["outPath"][0:31])

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

nix_toolchain = rule(
    impl = __nix_drv_impl,
    attrs = {},
)

## ---------------------------------------------------------------------

def nix_get_bin(ts: "dependency", bin: "string"):
    return cmd_args(ts[NixRealizationInfo].rootdir, format = "{}/out/bin/" + bin)

def nix_toolchain_dep(name: "string"):
    return attrs.default_only(attrs.dep(default = "nix//{}".format(name)))
