# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# Global import shim; anything exported here is available in *all* BUILD files!

load("@prelude//basics/attributes.bzl", "attributes")
load("@prelude//basics/providers.bzl", "providers")

load_symbols(providers)
