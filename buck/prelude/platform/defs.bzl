# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

def _execution_platform_impl(ctx: "context") -> ["provider"]:
    constraints = dict()
    constraints.update(ctx.attrs.cpu_configuration[ConfigurationInfo].constraints)
    constraints.update(ctx.attrs.os_configuration[ConfigurationInfo].constraints)
    cfg = ConfigurationInfo(constraints = constraints, values = {})

    name = ctx.label.raw_target()
    platform = ExecutionPlatformInfo(
        label = name,
        configuration = cfg,
        executor_config = CommandExecutorConfig(
            local_enabled = True,
            remote_enabled = False,
            use_windows_path_separators = False,
        ),
    )

    return [
        DefaultInfo(),
        platform,
        PlatformInfo(label = str(name), configuration = cfg),
        ExecutionPlatformRegistrationInfo(platforms = [platform]),
    ]

execution_platform = rule(
    impl = _execution_platform_impl,
    attrs = {
        "cpu_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "os_configuration": attrs.dep(providers = [ConfigurationInfo]),
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

def _nix_system() -> str.type:
    arch = host_info().arch
    os = host_info().os
    if arch.is_aarch64 and os.is_linux:
        return "aarch64-linux"
    elif arch.is_x86_64 and os.is_linux:
        return "x86_64-linux"
    elif arch.is_aarch64 and os.is_macos:
        return "aarch64-darwin"
    elif arch.is_x86_64 and os.is_macos:
        return "x86_64-darwin"
    else:
        fail("Unsupported host platform: %s" % host_info())

host_config = struct(
    cpu = _host_cpu_configuration(),
    os = _host_os_configuration(),
    nix_system = _nix_system(),
)

def generate_platforms(variants):
    for (cpu, os) in variants:
        execution_platform(
            name = "{}-{}".format(cpu, os),
            cpu_configuration = "prelude//platform/cpu:{}".format(cpu),
            os_configuration = "prelude//platform/os:{}".format(os),
            visibility = [ "prelude//...", "nix//..." ],
        )

    # Finally, generate the default platform selection, which matches the host
    # platform.
    execution_platform(
        name = "default",
        cpu_configuration = _host_cpu_configuration(),
        os_configuration = _host_os_configuration(),
        visibility = [ "prelude//...", "nix//..." ],
    )
