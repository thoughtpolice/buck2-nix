# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/pkg.bzl -- Support for PACKAGE file metadata
#
# HOW TO USE THIS MODULE:
#
# APIs for PACKAGE files. The following functions are available:
#   - owner(name: string) -> NoneType
#   - license(s: string) -> NoneType
# These are loaded implicitly by the prelude.
#
# APIs for rules, macros, etc. The following functions are available:
#   - pkg.rule_with_metadata(**kwargs) -> rule
#   - pkg.rule_apply_metadata(fn) -> fn
#
# Load this module with: load("@prelude//basics/pkg.bzl", "pkg")

"""PACKAGE file support."""

## ---------------------------------------------------------------------------------------------------------------------

__VALID_OWNERS = [
    "@aseipp"
]

def owner(name: "string") -> "NoneType":
    """Set the owner of the current package."""

    if name not in __VALID_OWNERS:
        fail(
            """Invalid owner: {}

            The list of valid owners can be seen in @prelude//basics/pkg.bzl
            """.format(name)
        )

    return write_package_value('meta.owner', name)

def license(s: "string") -> "NoneType":
    """Set the license of the current package."""
    return write_package_value('meta.license', s.strip())

def description(s: "string") -> "NoneType":
    """Set the description of the current package."""
    return write_package_value('meta.description', s.strip())

def version(s: "string") -> "NoneType":
    """Set the version of the current package."""

    # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    r = "^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
    if not regex_match(r, s):
        fail("Invalid version, must be semver-style: {}".format(s))
    return write_package_value('meta.version', s.strip())

## ---------------------------------------------------------------------------------------------------------------------

def __rule_with_metadata(**kwargs):
    """A wrapper around `rule()` that adds metadata to the rule as part of its attributes."""
    kwargs['attrs'] = kwargs['attrs'] | {
        "__meta_owner": attrs.string(),
        "__meta_license": attrs.string(),
        "__meta_description": attrs.option(attrs.string(), default = None),
        "__meta_version": attrs.option(attrs.string(), default = None),
    }
    return rule(**kwargs)

def __rule_apply_metadata(fn):
    """A wrapper around a rule function that applies metadata from the local PACKAGE to the rule."""
    def k(**kwargs):
        fn(
            __meta_license = read_package_value('meta.license'),
            __meta_owner = read_package_value('meta.owner'),
            __meta_description = read_package_value('meta.description'),
            __meta_version = read_package_value('meta.version'),
            **kwargs
        )
    return k

## ---------------------------------------------------------------------------------------------------------------------

pkg = struct(
    rule_with_metadata = __rule_with_metadata,
    rule_apply_metadata = __rule_apply_metadata,
)
