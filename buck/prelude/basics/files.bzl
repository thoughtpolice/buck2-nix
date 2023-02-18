# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/files.bzl -- File utilities.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/files.bzl", "files")

"""Rules for managing and manipulating files."""

## ---------------------------------------------------------------------------------------------------------------------

ExportFileDescriptionMode = [ "reference", "copy" ]

## ---------------------------------------------------------------------------------------------------------------------

def __filegroup_impl(ctx: "context") -> ["provider"]:
    if type(ctx.attrs.srcs) == type({}):
        srcs = ctx.attrs.srcs
    else:
        srcs = { src.short_path: src for src in ctx.attrs.srcs }

    output = ctx.actions.copied_dir(ctx.label.name, srcs)
    return [ DefaultInfo(default_output = output) ]

__filegroup = rule(
    doc = """Create a directory that contains links to a list of srcs.

    Each symlink is based on the shortpath for the given `srcs[x]`. The output
    directory uses `name` for its name.
    """,
    impl = __filegroup_impl,
    attrs = {
        "srcs": attrs.option(attrs.named_set(attrs.source(), sorted = False), default = None),
    },
)

## ---------------------------------------------------------------------------------------------------------------------

def __export_file_impl(ctx: "context") -> ["provider"]:
    copy = ctx.attrs.mode != "reference"

    if copy:
        dest = ctx.label.name if ctx.attrs.out == None else ctx.attrs.out
        output = ctx.actions.copy_file(dest, ctx.attrs.src)
    elif ctx.attrs.out != None:
        fail("export_file does not allow specifying `out` without also specifying `mode = 'copy'`")
    else:
        output = ctx.attrs.src

    return [
        DefaultInfo(default_output = output),
    ]

__export_file = rule(
    doc = """Export a file.""",
    impl = __export_file_impl,
    attrs = {
        "src": attrs.source(),
        "out": attrs.option(attrs.string(), default = None),
        "mode": attrs.option(attrs.enum(ExportFileDescriptionMode), default = None),
    },
)

def __export_file_m(name, **kwargs):
    if not "src" in kwargs:
        kwargs["src"] = name
    __export_file(name=name, **kwargs)

## ---------------------------------------------------------------------------------------------------------------------

files = struct(
    group = __filegroup,
    export = __export_file_m,

    attributes = {
        "ExportFileDescriptionMode": ExportFileDescriptionMode,
    },
    providers = {},
)
