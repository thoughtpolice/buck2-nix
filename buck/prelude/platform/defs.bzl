# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//platform/defs.bzl -- platform and host definitions
#
# HOW TO USE THIS MODULE:
#
#    load("@prelude//platform/defs.bzl", "host_config")

"""Platform and host definitions."""

## ---------------------------------------------------------------------------------------------------------------------

def _execution_platform_impl(ctx: "context") -> ["provider"]:
    constraints = dict()
    constraints.update(ctx.attrs.cpu_configuration[ConfigurationInfo].constraints)
    constraints.update(ctx.attrs.os_configuration[ConfigurationInfo].constraints)
    cfg = ConfigurationInfo(constraints = constraints, values = {})

    name = ctx.label.raw_target()

    # Configuration of how a command should be executed.
    exe_cfg = CommandExecutorConfig(
        # Whether to use local execution for this execution platform. If both
        # remote_enabled and local_enabled are True, we will use the hybrid
        # executor
        local_enabled = True,

        # Whether to use remote execution for this execution platform
        remote_enabled = ctx.attrs.remote_enabled,

        # Whether to use the "limited" hybrid executor. If the hybrid
        # executor is active, by default, it will race the two executors
        # to completion until one finishes. If the limited hybrid executor
        # is enabled, then both are exposed, but only the preferred one
        # is chosen. Finally, if allow_limited_hybrid_fallbacks is true,
        # then if the preferred executor fails, the other executor will be
        # tried.
        use_limited_hybrid = ctx.attrs.remote_enabled,

        # Use and query the RE cache
        remote_cache_enabled = ctx.attrs.remote_enabled,

        # Whether to upload local actions to the RE cache
        allow_cache_uploads = ctx.attrs.remote_enabled,

        # # Whether to use Windows path separators in command line arguments
        use_windows_path_separators = False,

        # Properties for remote execution for this platform. BuildBarn will
        # match these properties against the properties of the remote workers it
        # has attached; all fields must match.
        remote_execution_properties = {
            "OSFamily": "Linux",
            "container-image": "nix-bb-runner",
        },

        # The use case to use when communicating with RE.
        remote_execution_use_case = "buck2-default",

        # How to express output paths to RE. This is used internally for the
        # FB RE implementation and the FOSS implementation; strict means that
        # the RE implementation should expect the output paths to be specified
        # as files or directories in all cases, and that's what the Remote
        # Execution API expects. So this will never change.
        remote_output_paths = "strict",
    )

    exe_platform = ExecutionPlatformInfo(
        label = name,
        configuration = cfg,
        executor_config = exe_cfg,
    )

    return [
        DefaultInfo(),
        exe_platform,
        PlatformInfo(label = str(name), configuration = cfg),
        ExecutionPlatformRegistrationInfo(platforms = [exe_platform]),
    ]

__execution_platform = rule(
    impl = _execution_platform_impl,
    attrs = {
        "cpu_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "os_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "remote_enabled": attrs.bool(default = False),
    },
)

def _host_cpu_configuration() -> str.type:
    arch = host_info().arch
    if arch.is_aarch64:
        return "prelude//platform/cpu:aarch64"
    else:
        return "prelude//platform/cpu:x86_64"

def _host_os_configuration() -> str.type:
    os = host_info().os
    if os.is_macos:
        return "prelude//platform/os:darwin"
    else:
        return "prelude//platform/os:linux"

host_config = struct(
    cpu = _host_cpu_configuration(),
    os = _host_os_configuration(),
)

def generate_platforms(variants):
    """Generate execution platforms for the given variants, as well as a default
    execution platform matching the host platform."""

    for (cpu, os) in variants:
        cpu_configuration = "prelude//platform/cpu:{}".format(cpu)
        os_configuration = "prelude//platform/os:{}".format(os)
        visibility = [ "prelude//..." ]

        __execution_platform(
            name = "{}-{}".format(cpu, os),
            cpu_configuration = cpu_configuration,
            os_configuration = os_configuration,
            visibility = visibility,
        )

        __execution_platform(
            name = "{}-{}-remote".format(cpu, os),
            cpu_configuration = cpu_configuration,
            os_configuration = os_configuration,
            remote_enabled = True,
            visibility = visibility,
        )

    use_remote_by_default = False
    re_enabled = read_root_config("buck2_re_client", "enabled", "false")
    if host_info().os.is_linux and not host_info().arch.is_aarch64:
        use_remote_by_default = "true" == re_enabled
    if re_enabled == "force-true": # escape hatch
        use_remote_by_default = True

    __execution_platform(
        name = "default",
        cpu_configuration = _host_cpu_configuration(),
        os_configuration = _host_os_configuration(),
        remote_enabled = use_remote_by_default,
        visibility = [ "prelude//..." ],
    )
