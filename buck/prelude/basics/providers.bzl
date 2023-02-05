# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: Apache-2.0

# @prelude//:providers.bzl -- Build info providers for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:providers.bzl", ...)

## ---------------------------------------------------------------------------------------------------------------------

NixStoreOutputInfo = provider(fields = [ "path" ])

## ---------------------------------------------------------------------------------------------------------------------

providers = {
    "NixStoreOutputInfo": NixStoreOutputInfo,
}

def _update(s):
    p = getattr(s, "providers", None)
    providers.update([(k, v) for k, v in p.items()])

load("@prelude//nixpkgs.bzl", "nix"); _update(nix)
load("@prelude//toolchains/bash/main.bzl", "bash"); _update(bash)
load("@prelude//toolchains/rust/main.bzl", "rust"); _update(rust)
load("@prelude//toolchains/zip/main.bzl", "zipfile"); _update(zipfile)
