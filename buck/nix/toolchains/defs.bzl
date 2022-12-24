# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@nix//toolchains/bzl/x86_64-linux.bzl", __x86_64_linux_toolchains__ = "toolchains", __x86_64_linux_depgraph__ = "depgraph")
#load("@nix//toolchains/bzl/aarch64-linux.bzl", __aarch64_linux_toolchains__ = "toolchains", __aarch64_linux_depgraph__ = "depgraph")

toolchains = struct(
    x86_64_linux  = __x86_64_linux_toolchains__,
#    aarch64_linux = __aarch64_linux_toolchains__,
)

depgraph = struct(
    x86_64_linux  = __x86_64_linux_depgraph__,
#    aarch64_linux = __aarch64_linux_depgraph__,
)
