# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

load("@prelude//basics/config.bzl", "config")

config.constraint.declare(name = "os", visibility = [ "PUBLIC" ])
config.constraint.value(name = "linux",  constraint = ":os", visibility = [ "PUBLIC" ])
config.constraint.value(name = "darwin", constraint = ":os", visibility = [ "PUBLIC" ])
