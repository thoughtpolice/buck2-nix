load("@prelude//toolchains/bash/main.bzl", "bash")

bash.run(
    name = "echo-test",
    src = "echo-test.sh",
)

alias(
    name = "main",
    actual = select({
        "prelude//platform/os:linux": ":echo-test",
    }),
)
