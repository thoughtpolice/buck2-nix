# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@prelude//basics/config.bzl", "config")

config.constraint.declare(name = "cpu", visibility = [ "PUBLIC" ])
config.constraint.value(name = "x86_64", constraint = ":cpu", visibility = [ "PUBLIC" ])
config.constraint.value(name = "aarch64", constraint = ":cpu", visibility = [ "PUBLIC" ])
