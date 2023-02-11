# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/filegroup.bzl -- filegroup() rule.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/filegroup.bzl", "filegroup")

"""filegroup() rule."""

## ---------------------------------------------------------------------------------------------------------------------

def __filegroup(ctx: "context") -> ["provider"]:
    if type(ctx.attrs.srcs) == type({}):
        srcs = ctx.attrs.srcs
    else:
        srcs = { src.short_path: src for src in ctx.attrs.srcs }

    output = ctx.actions.copied_dir(ctx.label.name, srcs)
    return [ DefaultInfo(default_output = output) ]

filegroup = rule(
    doc = """Create a directory that contains links to a list of srcs.

    Each symlink is based on the shortpath for the given `srcs[x]`. The output
    directory uses `name` for its name.
    """,
    impl = __filegroup,
    attrs = {
        "srcs": attrs.option(attrs.named_set(attrs.source(), sorted = False), default = None),
    },
)
