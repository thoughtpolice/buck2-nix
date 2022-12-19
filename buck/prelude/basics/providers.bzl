# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//:providers.bzl -- Build info providers for Buck.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//:providers.bzl", ...)

## ---------------------------------------------------------------------------------------------------------------------

NixRealizationInfo = provider(fields = [ "rootdir" ])

NixStoreOutputInfo = provider(fields = [ "path" ])

## ---------------------------------------------------------------------------------------------------------------------

providers = {
    "NixRealizationInfo": NixRealizationInfo,
    "NixStoreOutputInfo": NixStoreOutputInfo,
}
