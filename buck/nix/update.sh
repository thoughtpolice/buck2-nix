#! /usr/bin/env bash
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

set -e
set -o pipefail

# ------------------------------------------------------------------------------

# NOTE: you should occasionally do this from a shell:
#
#     $ nix run nixpkgs#shellcheck -- ./buck/nix/update.sh

FLAKE=0
BUCK2=0
TOOLCHAINS=0
SPDX=0
CACHE=0

root=$(sl root)

usage() {
  echo
  echo "update.sh: perform various updates to Nix and Buck related data"
  cat <<EOF
Usage:

    buck run nix://:update -- [-fbtca]

  This tool is largely responsible for re-generating Buck and Nix related data
  in an automated way so things are easy to keep up to date.

  Currently you can pass the following flags, to perform various combinations of
  the following steps, in the following given order:

    --flake|-f         Step 1: Update the flake.lock file.
    --buck2|-b         Step 2: Update buck2 nix expression
    --toolchains|-t    Step 3: Re-generate toolchain descriptions
    --spdx|-s          Step 4: Re-generate SPDX license data
    --cache|-c         Step 5: Upload toolchain data to cache

  Or, to do everything at once:

    --all|-a           Run all steps in the above order

EOF
  exit 2
}

# ------------------------------------------------------------------------------

PARSED_ARGUMENTS=$(getopt -an update.sh -o hfbtcsa --long help,flake,buck2,toolchains,cache,spdx,all -- "$@")
VALID_ARGUMENTS=$?
[ "$VALID_ARGUMENTS" != "0" ] && usage

eval set -- "$PARSED_ARGUMENTS"
while : ; do
  case "$1" in
    -h | --help)       usage ;;
    # XXX (aseipp): always update toolchains when updating the flake, since not
    # doing so is basically an error
    -f | --flake)      FLAKE=1; TOOLCHAINS=1 ; shift ;;
    -b | --buck2)      BUCK2=1               ; shift ;;
    -t | --toolchains) TOOLCHAINS=1          ; shift ;;
    -s | --spdx)       SPDX=1                ; shift ;;
    -c | --cache)      CACHE=1               ; shift ;;
    -a | --all)        FLAKE=1; BUCK2=1; TOOLCHAINS=1; SPDX=1; CACHE=1; shift ;;

    --) shift; break ;;
    *) echo "Unexpected option: $1 - this should not happen." && usage ;;
  esac
done

[ "$FLAKE" = "0" ] && \
  [ "$BUCK2" = "0" ] && \
  [ "$TOOLCHAINS" = "0" ] && \
  [ "$SPDX" = "0" ] && \
  [ "$CACHE" = "0" ] && \
  usage

printf "\nUpdating flake=$FLAKE, buck2=$BUCK2, toolchains=$TOOLCHAINS, spdx=$SPDX, cache=$CACHE\n\n"

# ------------------------------------------------------------------------------

## Step 1: Update the flake.lock file.

if [ "$FLAKE" = "1" ]; then
  nix flake --accept-flake-config update "${root}/buck/nix"
fi

# ------------------------------------------------------------------------------

## Step 2: Update buck2 nix expression

if [ "$BUCK2" = "1" ]; then

  # update the hash, revision, and version
  echo "BUCK2: generating new version information"
  r=$(curl -sq https://api.github.com/repos/facebookincubator/buck2/commits/main | jq -r '.sha')
  v=unstable-$(date +"%Y-%m-%d")
  i=$(nix-prefetch-git --quiet --url https://github.com/facebookincubator/buck2 --rev "$r")
  h=$(echo "$i" | jq -r '.sha256' | xargs nix hash to-sri --type sha256)
  p=$(echo "$i" | jq -r '.path')

  sed -i 's#rev\s*=\s*".*";#rev = "'"$r"'";#'         "$root/buck/nix/buck2/default.nix"
  sed -i 's#hash\s*=\s*".*";#hash = "'"$h"'";#'       "$root/buck/nix/buck2/default.nix"
  sed -i 's#version\s*=\s*".*";#version = "'"$v"'";#' "$root/buck/nix/buck2/default.nix"

  # upstream doesn't have their own Cargo.lock file, so we need to generate one
  t=$(mktemp -d)
  d="$t/buck2"

  echo "BUCK2: generating new Cargo.lock file"
  cp -r "$p" "$d" && chmod -R +w "$d" && (cd "$d" && cargo --quiet generate-lockfile)
  cp "$d/Cargo.lock" "$root/buck/nix/buck2/Cargo.lock"

  # update the toolchain based on the rust-toolchain file
  echo "BUCK2: updating rust-toolchain setting"
  channel=$(grep -oP 'channel = \"\K\w.+(?=\")' "$p/rust-toolchain")
  if [[ $channel == nightly-* ]]; then
    version=$(echo "$channel" | sed 's/nightly-//')
    sed -i 's/rustChannel\s*=\s*".*";/rustChannel = "nightly";/'      "$root/buck/nix/buck2/default.nix"
    sed -i 's/rustVersion\s*=\s*".*";/rustVersion = "'"$version"'";/' "$root/buck/nix/buck2/default.nix"
  else
    echo "Unknown channel: $channel"
    exit 1
  fi

  # done
  printf "BUCK2: done\n\n"
  rm -r -f "$t"
  unset t d r v i h p channel version
fi

# ------------------------------------------------------------------------------

## Step 3: Re-evaluate toolchain descriptions, and generate Buck dependency data

if [ "$TOOLCHAINS" = "1" ]; then
  nix build --accept-flake-config --print-out-paths "${root}/buck/nix#world"
  currentSystem=$(nix eval --impure --raw --expr 'builtins.currentSystem')
  platfile="${root}/buck/nix/toolchains/platforms/_${currentSystem}.bzl"

  set -x
  jq -r '.toolchainPackages | to_entries[] | [ .key, .value ] | join(" ")' ./result \
    | while read -r name out; do echo "{ \"${name}\": \"${out:11}\" }"; done \
    | jq -n 'reduce inputs as $in (null; . + $in)' \
    | (cat <<EOF
# SPDX-License-Identifier: MIT OR Apache-2.0

# NOTE: DO NOT EDIT MANUALLY!
# NOTE: This file is @generated by the following command:
#
#    buck run nix//:update -- -t
#
# NOTE: Please run the above command to regenerate this file.

# @nix//toolchains/data.bzl -- nix dependency graph information for buck

# A mapping of all publicly available toolchains for Buck targets to consume,
# keyed by name, with their Nix hash as the value.
toolchains = $(cat /dev/stdin)
EOF
    ) > "${platfile}"
  jq -r '.toolchainPackages | to_entries[] | .value' ./result \
    | xargs nix path-info -r --json \
    | jq '.[] | with_entries(select([.key] | inside(["path","deriver","references"]))) | { (.path[11:]): ({ "d": .deriver[11:], "r": (.references - [.path])  | map(.[11:]) } | del(..|select(. == null))) }' \
    | jq -n 'reduce inputs as $in (null; . + $in)' \
    | (cat <<EOF

# The "shallow" dependency graph of all Nix hashes, keyed by Nix hash, with
# the value being a list of Nix hashes that are referenced by the key.
# This graph is used to download dependencies on-demand when building targets,
# but is not publicly exposed; only 'toolchains' is.
depgraph = $(cat /dev/stdin)
EOF
    ) >> "${platfile}"
  rm ./result*
fi

# ------------------------------------------------------------------------------

## Step 4: Re-generate SPDX license data

if [ "$SPDX" = "1" ]; then
  # update the hash, revision, and version
  echo "SPDX: generating new license information"
  r=$(curl -sq https://api.github.com/repos/spdx/license-list-data/commits/main | jq -r '.sha')
  v=unstable-$(date +"%Y-%m-%d")
  i=$(nix-prefetch-git --quiet --url https://github.com/spdx/license-list-data --rev "$r")
  p=$(echo "$i" | jq -r '.path')

  datfile="${root}/buck/prelude/basics/spdx.bzl"
  set -x
  cat "$p/json/licenses.json" \
    | sed 's/\sfalse/ False/g' \
    | sed 's/\strue/ True/g' \
    | (cat <<EOF
# SPDX-License-Identifier: MIT OR Apache-2.0

# NOTE: DO NOT EDIT MANUALLY!
# NOTE: This file is @generated by the following command:
#
#    buck run nix//:update -- -s
#
# NOTE: Please run the above command to regenerate this file.

# @prelude//basics/spdx.bzl -- SPDX license data for buck

# Raw SPDX license data
license_list = $(cat /dev/stdin)
EOF
    ) > "${datfile}"
  cat "$p/json/exceptions.json" \
    | sed 's/\sfalse/ False/g' \
    | sed 's/\strue/ True/g' \
    | (cat <<EOF

# Raw SPDX exception data
exception_list = $(cat /dev/stdin)
EOF
    ) >> "${datfile}"
fi

# ------------------------------------------------------------------------------

## Step 5: Rebuild and push the cache

if [ "$CACHE" = "1" ]; then
  tsbin="/nix/var/nix/profiles/default/bin/ts"
  user=${USER:-root}
  [[ ! -f "$tsbin" ]] && tsbin="/nix/var/nix/profiles/per-user/$user/profile/bin/ts"
  [[ ! -f "$tsbin" ]] && echo "no task spooler installed! exiting" && exit 2

  export S3_BUCKET="${S3_BUCKET:-__S3_BUCKET__}"
  export S3_ENDPOINT="${S3_ENDPOINT:-__S3_ENDPOINT__}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-__AWS_ACCESS_KEY_ID__}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-__AWS_SECRET_ACCESS_KEY__}"
  export NIX_CACHE_PRIVATE_KEY="${NIX_CACHE_PRIVATE_KEY:-__NIX_CACHE_PRIVATE_KEY__}"

  [ "$S3_BUCKET" == "__S3_BUCKET__" ] && echo "S3_BUCKET not set, exiting" && exit 3
  [ "$S3_ENDPOINT" == "__S3_ENDPOINT__" ] && echo "S3_ENDPOINT not set, exiting" && exit 4
  [ "$AWS_ACCESS_KEY_ID" == "__AWS_ACCESS_KEY_ID__" ] && echo "AWS_ACCESS_KEY_ID not set, exiting" && exit 5
  [ "$AWS_SECRET_ACCESS_KEY" == "__AWS_SECRET_ACCESS_KEY__" ] && echo "AWS_SECRET_ACCESS_KEY not set, exiting" && exit 6
  [ "$NIX_CACHE_PRIVATE_KEY" == "__NIX_CACHE_PRIVATE_KEY__" ] && echo "NIX_CACHE_PRIVATE_KEY not set, exiting" && exit 7

  # [tag:full-nix-cache-push] see also: https://www.haskellforall.com/2022/10/how-to-correctly-cache-build-time.html
  mapfile -t TARGETS < <(nix build --accept-flake-config --no-link --print-out-paths ./buck/nix#attrs | xargs cat | xargs printf './buck/nix#%s\n')
  mapfile -t BUILDS < <(echo "${TARGETS[@]}" | xargs nix build --accept-flake-config --print-out-paths --no-link)
  mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --derivation)
  mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)

  for x in "${DEPENDENCIES[@]}"; do echo "$x"; done \
    | while mapfile -t -n 32 ary && ((${#ary[@]})); do \
        OUT_PATHS="${ary[@]}"; \
        $tsbin /nix/var/nix/profiles/default/bin/nix copy \
          --to s3://"$S3_BUCKET"\?write-nar-listing=1\&index-debug-info=1\&compression=zstd\&scheme=https\&endpoint="$S3_ENDPOINT"\&secret-key=<(echo "$NIX_CACHE_PRIVATE_KEY") \
          $OUT_PATHS; \
      done
fi

# ------------------------------------------------------------------------------
