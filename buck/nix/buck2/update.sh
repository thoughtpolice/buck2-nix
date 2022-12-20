#!/usr/bin/env bash

set -xueo pipefail

root=$(sl root)
t=$(mktemp -d)
d="$t/buck2"

# update the hash, revision, and version
r=$(curl -sq https://api.github.com/repos/facebookincubator/buck2/commits/main | jq -r '.sha')
v=unstable-$(date +"%Y-%m-%d")
h=$(nix run nixpkgs#nix-prefetch-git -- --url https://github.com/facebookincubator/buck2 --rev "$r" \
  | jq -r '.sha256' \
  | xargs nix hash to-sri --type sha256 \
  )
sed -i 's#rev\s*=\s*".*";#rev = "'"$r"'";#'         "$root/buck/nix/buck2/default.nix"
sed -i 's#hash\s*=\s*".*";#hash = "'"$h"'";#'        "$root/buck/nix/buck2/default.nix"
sed -i 's#version\s*=\s*".*";#version = "'"$v"'";#' "$root/buck/nix/buck2/default.nix"

# upstream doesn't have their own Cargo.lock file, so we need to generate one
git clone https://github.com/facebookincubator/buck2 "$d"
(cd "$d" && git reset --hard "$r" && cargo generate-lockfile)
cp "$d/Cargo.lock" "$root/buck/nix/buck2/Cargo.lock"

# update the toolchain based on the rust-toolchain file
channel=$(grep -oP 'channel = \"\K\w.+(?=\")' "$d/rust-toolchain")
if [[ $channel == nightly-* ]]; then
  version=$(echo "$channel" | sed 's/nightly-//')
  sed -i 's/rustChannel\s*=\s*".*";/rustChannel = "nightly";/'      "$root/buck/nix/buck2/default.nix"
  sed -i 's/rustVersion\s*=\s*".*";/rustVersion = "'"$version"'";/' "$root/buck/nix/buck2/default.nix"
else
  echo "Unknown channel: $channel"
  exit 1
fi

# done
rm -r -f "$t"
