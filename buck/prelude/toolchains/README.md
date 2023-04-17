# Toolchain definitions

This directory includes all the toolchains you can use in your own targets. Look
inside each subdirectory to see the exported rules, etc.

The top level `BUILD` file should only be used to download globally useful
things like the nixpkgs source code, etc. Specific toolchain targets are in the
`BUILD` file in their respective subdirectories.
