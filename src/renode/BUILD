load("@prelude//toolchains/nixpkgs.bzl", "nix")

genrule(
    name = 'hifive-unleashed',
    executable = True,
    sandbox = False,
    type = "exe",

    srcs = [ ":renode-test-srcs" ],

    out = "run-renode.sh",
    cmd = """
       touch $OUT && chmod +x $OUT
       echo "#!/usr/bin/env bash" > $OUT
       echo $(exe :renode) \\
         -e \"'set bbl @$SRCS/hifive-unleashed-bbl.bin'\" \\
         -e \"'set fdt @$SRCS/hifive-unleashed.dtb'\" \\
         -e \"'set kernel @$SRCS/hifive-unleashed-vmlinux.bin'\" \\
         -e \"'include @$SRCS/unleashed.resc\'" \\
         -e \"'showAnalyzer sysbus.uart0'\" \\
         -e \"'runMacro \$reset'\" \\
         -e start >> $OUT
    """,
    target_compatible_with = [
      "prelude//platform/cpu:x86_64"
    ],
)

# XXX FIXME: renode testing is broken. it doesn't work because robot framework
# changes the CWD of the renode executable so that relative paths (pointing to
# buck-out) do not work; i'm not sure how to re-hermeticize this...

# genrule(
#     name = 'hifive-unleashed-test',
#     type = "test",
#     sandbox = False,
#     srcs = [ ":renode-test-srcs" ],

#     outs = {
#         "robot_output.xml": ["robot_output.xml"],
#         "log.html":         ["log.html"],
#         "report.html":      ["report.html"],
#     },

#     cmd = """
#       $(exe :renode-test) \\
#         --variable BBL:$SRCS/hifive-unleashed-bbl.bin \\
#         --variable FDT:$SRCS/hifive-unleashed.dtb \\
#         --variable KERNEL:$SRCS/hifive-unleashed-vmlinux.bin \\
#         --variable MACHINFO:$SRCS/unleashed.resc \\
#         -r $OUT $SRCS/test.robot
#     """,
# )

files.group(
    name = "renode-test-srcs",
    srcs = [
        ":test.robot",
        ":unleashed.resc",
        ":hifive-unleashed-bbl.bin",
        ":hifive-unleashed.dtb",
        ":hifive-unleashed-vmlinux.bin",
    ],
)

files.export(name = "unleashed.resc")
files.export(name = "test.robot")

download.multi_file({
    "hifive-unleashed-bbl.bin": {
        "url": "https://dl.antmicro.com/projects/renode/hifive-unleashed--bbl.elf-s_17219640-c7e1b920bf81be4062f467d9ecf689dbf7f29c7a",
        "hash": "sha256-LyjAeCBaJ26tDsQH50zEOA14WZHpHwUU0V09HOZPsMM=",
    },
    "hifive-unleashed.dtb": {
        "url": "https://dl.antmicro.com/projects/renode/hifive-unleashed--devicetree.dtb-s_10532-70cd4fc9f3b4df929eba6e6f22d02e6ce4c17bd1",
        "hash": "sha256-h3IA9N+RX1phj/pAFmfGICtX8/mb0kPD3W9IphlZyx4=",
    },
    "hifive-unleashed-vmlinux.bin": {
        "url": "https://dl.antmicro.com/projects/renode/hifive-unleashed--vmlinux.elf-s_80421976-46788813c50dc7eb1a1a33c1730ca633616f75f5",
        "hash": "sha256-wKQ+ocnE5WbOqeUhItMqeHVq5XEvoQEm7ywH7+O9Tec=",
    },
})

nix.rules.build_file(
    name = "renode",
    src = "renode.nix",
    binary = "bin/renode",
    target_compatible_with = [
      "prelude//platform/cpu:x86_64"
    ],
)

nix.rules.build_file(
    name = "renode-test",
    src = "renode.nix",
    binary = "bin/renode-test",
    target_compatible_with = [
      "prelude//platform/cpu:x86_64"
    ],
)
