# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//config.bzl -- configuration for the prelude.
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//config.bzl", "config")

"""Configuration rules and information."""

## ---------------------------------------------------------------------------------------------------------------------

# config_setting() accepts a list of constraint_values and a list of values
# (buckconfig keys + expected values) and matches if all of those match.
#
# This is implemented as forming a single ConfigurationInfo from the union of the
# referenced values and the config keys.
#
# Attributes:
#   "constraint_values": attrs.list(attrs.configuration_label(), default = []),
#   "values": attrs.dict(key = attrs.string(), value = attrs.string(), sorted = False, default = {}),
def _config_setting_impl(ctx):
    subinfos = [_constraint_values_to_configuration(ctx.attrs.constraints)]
    subinfos.append(ConfigurationInfo(constraints = {}, values = ctx.attrs.values))
    return [DefaultInfo(), _configuration_info_union(subinfos)]

# constraint_setting() targets just declare the existence of a constraint.
def _constraint_setting_impl(ctx):
    return [DefaultInfo(), ConstraintSettingInfo(label = ctx.label.raw_target())]

# constraint_value() declares a specific value of a constraint_setting.
#
# Attributes:
#  constraint_setting: the target constraint that this is a value of
def _constraint_value_impl(ctx):
    constraint_value = ConstraintValueInfo(
        setting = ctx.attrs.constraint[ConstraintSettingInfo],
        label = ctx.label.raw_target(),
    )
    return [
        DefaultInfo(),
        constraint_value,
        # Provide `ConfigurationInfo` from `constraint_value` so it could be used as select key.
        ConfigurationInfo(constraints = {
            constraint_value.setting.label: constraint_value,
        }, values = {}),
    ]

# platform() declares a platform, it is a list of constraint values.
#
# Attributes:
#  constraint_values: list of constraint values that are set for this platform
#  deps: a list of platform target dependencies, the constraints from these platforms will be part of this platform (unless overriden)
def _platform_impl(ctx):
    subinfos = (
        [dep[PlatformInfo].configuration for dep in ctx.attrs.deps] +
        [_constraint_values_to_configuration(ctx.attrs.constraints)]
    )
    return [
        DefaultInfo(),
        PlatformInfo(
            label = str(ctx.label.raw_target()),
            # TODO(nga): current behavior is the last constraint value for constraint setting wins.
            #   This allows overriding constraint values from dependencies, and moreover,
            #   it allows overriding constraint values from constraint values listed
            #   in the same `constraint_values` attribute earlier.
            #   If this is intentional, state it explicitly.
            #   Otherwise, fix it.
            configuration = _configuration_info_union(subinfos),
        ),
    ]

def _configuration_info_union(infos):
    if len(infos) == 0:
        return ConfigurationInfo(
            constraints = {},
            values = {},
        )
    if len(infos) == 1:
        return infos[0]
    constraints = {k: v for info in infos for (k, v) in info.constraints.items()}
    values = {k: v for info in infos for (k, v) in info.values.items()}
    return ConfigurationInfo(
        constraints = constraints,
        values = values,
    )

def _constraint_values_to_configuration(values):
    return ConfigurationInfo(constraints = {
        info[ConstraintValueInfo].setting.label: info[ConstraintValueInfo]
        for info in values
    }, values = {})

## ---------------------------------------------------------------------------------------------------------------------

__config_setting = rule(
    doc = """A rule that defines a configuration setting.""",
    impl = _config_setting_impl,
    attrs = {
        "constraints": attrs.list(attrs.configuration_label(), default = []),
        "values": attrs.dict(key = attrs.string(), value = attrs.string(), sorted = False, default = {}),
        "within_view": attrs.option(attrs.option(attrs.list(attrs.string())), default = None),
    },
    is_configuration_rule = True,
)

__constraint_setting = rule(
    doc = """A rule that defines a constraint setting.""",
    impl = _constraint_setting_impl,
    attrs = {
        "within_view": attrs.option(attrs.option(attrs.list(attrs.string())), default = None),
    },
    is_configuration_rule = True,
)

__constraint_value = rule(
    doc = """A rule that defines a constraint value.""",
    impl = _constraint_value_impl,
    attrs = {
        "constraint": attrs.configuration_label(),
        "within_view": attrs.option(attrs.option(attrs.list(attrs.string())), default = None),
    },
    is_configuration_rule = True,
)

__platform = rule(
    doc = """A rule that defines a platform.""",
    impl = _platform_impl,
    attrs = {
        "constraints": attrs.list(attrs.configuration_label(), default = []),
        "deps": attrs.list(attrs.configuration_label(), default = []),
        "within_view": attrs.option(attrs.option(attrs.list(attrs.string())), default = None),
    },
    is_configuration_rule = True,
)

config = struct(
    platform = __platform,
    setting = __config_setting,
    constraint = __constraint_setting,
    value = __constraint_value,
)

## ---------------------------------------------------------------------------------------------------------------------
