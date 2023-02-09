# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: Apache-2.0

# @prelude//:providers.bzl -- Build info providers for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:providers.bzl", ...)

load("@prelude//nixpkgs.bzl", "nix");
load("@prelude//toolchains/bash/main.bzl", "bash");
load("@prelude//toolchains/rust/main.bzl", "rust");
load("@prelude//toolchains/zip/main.bzl", "zipfile");

## ---------------------------------------------------------------------------------------------------------------------

NixStoreOutputInfo = provider(fields = [ "path" ])

## ---------------------------------------------------------------------------------------------------------------------

providers = {
    "NixStoreOutputInfo": NixStoreOutputInfo,
}

def _update(s):
    p = getattr(s, "providers", None)
    providers.update([(k, v) for k, v in p.items()])

_update(nix)
_update(bash)
_update(rust)
_update(zipfile)
