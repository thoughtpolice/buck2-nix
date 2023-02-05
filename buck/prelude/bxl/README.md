# bxl scripts

This directory contains Buck Extension Language ("BXL") scripts for this
repository. They are scripts that integrate directly with Buck2 to perform
peripherial or useful tasks based directly on the underlying action graph.

All scripts are written as individual `.bzl` files, but exported through
`top.bxl` with the arguments configured there.

You should have a `bxl` command available in your shell. This abstracts away the
direct filepath needed to run these scripts by referencing a buck cell path
instead of a direct file path.

Try `bxl hello --bool_arg true`, and then look at `hello.bzl` to get an idea of
what's going on. The arguments for the `hello` script are specified, along with
the global `bxl` rule name, in `top.bxl`. The name `hello` in `bxl hello` refers
to this rule name.

## current scripts

fixme
