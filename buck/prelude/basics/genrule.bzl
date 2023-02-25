# SPDX-FileCopyrightText: © 2022 Meta Platforms, Inc. and affiliates.
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# @prelude//basics/genrule.bzl -- genrule() implementation.
#
# HOW TO USE THIS MODULE:
#
#    N/A. genrule() is available through the default Prelude, in any BUILD or TARGETS file.

"""genrule() implementation."""

## ---------------------------------------------------------------------------------------------------------------------

def _declare_output(ctx: "context", path: str.type) -> "artifact":
    if path == ".":
        return ctx.actions.declare_output("out", dir = True)
    elif path.endswith("/"):
        return ctx.actions.declare_output("out", path[:-1], dir = True)
    else:
        return ctx.actions.declare_output("out", path)

def _project_output(out: "artifact", path: str.type) -> "artifact":
    if path == ".":
        return out
    elif path.endswith("/"):
        return out.project(path[:-1], hide_prefix = True)
    else:
        return out.project(path, hide_prefix = True)

## ---------------------------------------------------------------------------------------------------------------------

def __genrule_impl(ctx: "context") -> ["provider"]:
    out_attr = ctx.attrs.out
    outs_attr = ctx.attrs.outs

    path_sep = "/"

    # TODO(cjhopman): verify output paths are ".", "./", or forward-relative.
    if out_attr != None:
        out_env = out_attr
        out_artifact = _declare_output(ctx, out_attr)
        named_outputs = {}
        default_outputs = [out_artifact]
    elif outs_attr != None:
        out_env = ""
        out_artifact = ctx.actions.declare_output("out", dir = True)

        named_outputs = {
            name: [_project_output(out_artifact, path) for path in outputs]
            for (name, outputs) in outs_attr.items()
        }

        default_outputs = [
            _project_output(out_artifact, path)
            for path in (ctx.attrs.default_outs or [])
        ]
        if len(default_outputs) == 0:
            # We want building to force something to be built, so make sure it contains at least one artifact
            default_outputs = [out_artifact]
    else:
        fail("One of `out` or `outs` should be set. Got `%s`" % repr(ctx.attrs))

    cmd = cmd_args(ctx.attrs.cmd)

    if type(ctx.attrs.srcs) == type([]):
        # FIXME: We should always use the short_path, but currently that is sometimes blank.
        # See fbcode//buck2/tests/targets/rules/genrule:genrule-dot-input for a test that exposes it.
        symlinks = {src.short_path: src for src in ctx.attrs.srcs}

        if len(symlinks) != len(ctx.attrs.srcs):
            for src in ctx.attrs.srcs:
                name = src.short_path
                if symlinks[name] != src:
                    msg = "genrule srcs include duplicative name: `{}`. ".format(name)
                    msg += "`{}` conflicts with `{}`".format(symlinks[name].owner, src.owner)
                    fail(msg)
    else:
        symlinks = ctx.attrs.srcs
    srcs_artifact = ctx.actions.symlinked_dir("srcs", symlinks)

    srcs = cmd_args()
    for symlink in symlinks:
        srcs.add(cmd_args(srcs_artifact, format = path_sep.join([".", "{}", symlink.replace("/", path_sep)])))
    env_vars = {
        "OUT": cmd_args(srcs_artifact, format = path_sep.join([".", "{}", "..", "out", out_env])),
        "SRCDIR": cmd_args(srcs_artifact, format = path_sep.join([".", "{}"])),
        "SRCS": srcs,
    } | {k: cmd_args(v) for k, v in getattr(ctx.attrs, "env", {}).items()}

    script = [
        # Use a somewhat unique exit code so this can get retried on RE (T99656531).
        cmd_args(srcs_artifact, format = "mkdir -p ./{}/../out || exit 99"),
        cmd_args("export TMP=${TMPDIR:-/tmp}"),
        cmd_args("set -e"),
    ]
    script_extension = "sh"

    script.append(cmd)

    # Some rules need to run from the build root, but for everything else, `cd`
    # into the sandboxed source dir and relative all paths to that.
    if ctx.attrs.sandbox:
        script = (
            # Change to the directory that genrules expect.
            [cmd_args(srcs_artifact, format = "cd {}")] +
            # Relative all paths in the command to the sandbox dir.
            [cmd.relative_to(srcs_artifact) for cmd in script]
        )

        # Relative all paths in the env to the sandbox dir.
        env_vars = {key: val.relative_to(srcs_artifact) for key, val in env_vars.items()}

    sh_script, sh_script_macros = ctx.actions.write(
        "sh/genrule.{}".format(script_extension),
        script,
        is_executable = True,
        allow_args = True,
    )

    oil_osh = cmd_args(ctx.attrs._oil[DefaultInfo].default_outputs[0], format="{}/bin/osh")
    script_args = [ oil_osh, sh_script ]

    category = "genrule"
    if ctx.attrs.type != None:
        # As of 09/2021, all genrule types were legal snake case if their dashes and periods were replaced with underscores.
        category += "_" + ctx.attrs.type.replace("-", "_").replace(".", "_")

    full_cmd = cmd_args(script_args).hidden([cmd, srcs_artifact, out_artifact.as_output(), sh_script_macros])
    ctx.actions.run(
        full_cmd,
        env = env_vars,
        category = category,
       #local_only = local_only,
       #allow_cache_upload = cacheable,
    )

    providers = []

    if ctx.attrs.executable:
        providers.append(RunInfo(args = cmd_args(default_outputs)))

    providers.append(
        DefaultInfo(
            default_outputs = default_outputs,
            sub_targets = {k: [DefaultInfo(default_outputs = v)] for (k, v) in named_outputs.items()},
        )
    )

    return providers

genrule = rule(
    impl = __genrule_impl,
    attrs = {
        "cmd": attrs.arg(),
        "srcs": attrs.named_set(attrs.source(), sorted = False, default = []),
        "default_outs": attrs.option(attrs.set(attrs.string(), sorted = False), default = None),
        "out": attrs.option(attrs.string(), default = None),
        "outs": attrs.option(attrs.dict(key = attrs.string(), value = attrs.set(attrs.string(), sorted = False), sorted = False), default = None),
        "type": attrs.option(attrs.string(), default = None),

        "labels": attrs.list(attrs.string(), default = []),
        "executable": attrs.bool(default = False),
        "sandbox": attrs.bool(default = True),

        "_oil": attrs.default_only(
            attrs.dep(
                default = "@prelude//toolchains/bash:oil",
                providers = [ DefaultInfo ]
            ),
        ),
    },

    doc = """Generate files from a shell command. genrule() can be used as a
    tool to build test harnesses or other intermediate shell commands that need
    to run as part of the build.

    When specifying inputs, you MUST specify the 'srcs' attribute. It can simply
    be a single file, a list of files, or a dictionary of named files. The $SRCS
    environment variable within the script will be replaced with these entries.
    Note that if srcs points to a list of *file* targets, then the $SRCS
    variable will simply be a space-separated list of those files. However, if
    you wish for $SRCS to instead point to a *directory* containing all of the
    files, then you should use files.export() to create a directory containing
    all of the files instead, and point 'srcs' to that instead.

    When specifying outputs, you MUST specify either the 'out' or 'outs'
    attribute. It is an error to specify both. The $OUT variable within the
    script will be replaced with the path to the output file, or an output
    directory if 'outs' is specified.

    The underlying command is run in a sandboxed environment if sandbox != False
    (the default is sandbox = True). Some commands do not need to run outside
    the sandbox, but some do, for example if they need to be run from the root
    of the project.

    The 'type' attribute is an arbitrary string; it will be used to categorize
    the genrule in the build log, so that it is easier to find the genrule or
    look it up later. Multiple genrules of the same type can be grouped this
    way.

    This rule is similar to `genrule` in Bazel or Buck, but it uses the Oil
    shell instead of Bash""",
)
