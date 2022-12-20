#!/usr/bin/env bash

set -x

cd $(sl root)/buck/nix
t=$(mktemp -d)
d="$t/buck2"

# 'nix-update' fails because Cargo.lock can't be updated, but it does
# the job of updating the hash anyway
nix run nixpkgs#nix-update -- \"packages/buck2\" --version branch --flake || true
r=$(nix eval --accept-flake-config --raw "$PWD#packages/buck2.src.rev")

git clone https://github.com/facebookincubator/buck2 "$d"
(cd "$d" && git reset --hard "$r" && cargo generate-lockfile)
cp "$d/Cargo.lock" "$PWD/buck2/Cargo.lock"

rm -r -f "$t"
