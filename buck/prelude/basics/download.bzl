# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/download.bzl -- download utilities
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//basics/download.bzl", "download")

"""Rules for downloading files and tarball assets."""

## ---------------------------------------------------------------------------------------------------------------------

def _download_tarball(ctx: "context") -> ["provider"]:
    dl_script, _ = ctx.actions.write(
        "download_{}.sh".format(ctx.label.name),
        [
            "#!/usr/bin/env bash",
            "set -xeuo pipefail",
            "[ -f /buildbarn/profile ] && source /buildbarn/profile",
            "curl -Lo \"$1\" {}".format(ctx.attrs.url),
            "mkdir -p \"$2\"",
            "tar xf \"$1\" -C \"$2\" --no-same-owner --strip-components=1",
            "hash=$(nix hash path --type sha256 \"$2\")",
            "if ! [ \"$hash\" = \"{}\" ]; then".format(ctx.attrs.hash),
            "  echo \"hash mismatch:\"",
            "  echo \"  expected '{}'\"".format(ctx.attrs.hash),
            "  echo \"       got '$hash'\"",
            "  exit 1",
            "fi",
            "", # XXX: newline for readability in terminal
        ],
        allow_args = True,
        is_executable = True,
    )

    tarball_out = ctx.actions.declare_output("{}.tar.gz".format(ctx.label.name))
    dir_out = ctx.actions.declare_output(ctx.label.name, dir = True)
    cmd = cmd_args([dl_script, tarball_out.as_output(), dir_out.as_output()])
    ctx.actions.run(cmd, category = "download_tarball", identifier = ctx.attrs.url)

    return [
        DefaultInfo(
            default_output = dir_out,
            sub_targets = {
                "tar": [ DefaultInfo(default_output = tarball_out) ]
            }
        ),
    ]

__tarball = rule(
    impl = _download_tarball,
    attrs = {
        "url": attrs.string(),
        # XXX: set a default to nixpkgs' lib.fakeHash, so it's always wrong, and must be fixed
        "hash": attrs.string(default = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="),
    },
    doc = """Download a 'fixed output' tarball from a URL. By 'fixed output', this means that
    the tarball is downloaded and extracted to a directory, and the hash of the
    directory is checked against the expected hash. This is useful for downloading
    tarballs that can contain the same content but have different hashes, such as
    git repositories, or tarballs compressed with different compression algorithms.
    """,
)

## ---------------------------------------------------------------------------------------------------------------------

def __file_impl(ctx: "context") -> ["provider"]:
    dl_script, _ = ctx.actions.write(
        "download_{}.sh".format(ctx.label.name),
        [
            "#!/usr/bin/env bash",
            "set -xeuo pipefail",
            "[ -f /buildbarn/profile ] && source /buildbarn/profile",
            "curl -Lo \"$1\" {}".format(ctx.attrs.url),
            "hash=$(nix hash path --type sha256 \"$1\")",
            "if ! [ \"$hash\" = \"{}\" ]; then".format(ctx.attrs.hash),
            "  echo \"hash mismatch:\"",
            "  echo \"  expected '{}'\"".format(ctx.attrs.hash),
            "  echo \"       got '$hash'\"",
            "  exit 1",
            "fi",
            "", # XXX: newline for readability in terminal
        ],
        allow_args = True,
        is_executable = True,
    )

    out = ctx.actions.declare_output(ctx.label.name)
    cmd = cmd_args([dl_script, out.as_output() ])
    ctx.actions.run(cmd, category = "download_file", identifier = ctx.attrs.url)

    return [ DefaultInfo(default_output = out) ]

__file = rule(
    impl = __file_impl,
    attrs = {
        "url": attrs.string(),
        # XXX: set a default to nixpkgs' lib.fakeHash, so it's always wrong, and must be fixed
        "hash": attrs.string(default = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="),
    },
    doc = """Download a file from a given URL, given a hash of the file.""",
)

## ---------------------------------------------------------------------------------------------------------------------

def multi_tarball(attrs):
    for (k, kwargs) in attrs.items():
        __tarball(name = k, **kwargs)

def multi_file(attrs):
    for (k, kwargs) in attrs.items():
        __file(name = k, **kwargs)

## ---------------------------------------------------------------------------------------------------------------------

download = struct(
    tarball = __tarball,
    file = __file,

    multi_tarball = multi_tarball,
    multi_file = multi_file,
)
