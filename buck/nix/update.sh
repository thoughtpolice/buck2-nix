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
CACHE=0

if [ ! -z "$IS_CI" ]; then
  root=$(git rev-parse --show-toplevel)
else
  root=$(sl root)
fi

usage() {
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
    --cache|-c         Step 3: Upload toolchain data to cache

  Or, to do everything at once:

    --all|-a           Run all steps in the above order

EOF
  exit 2
}

# ------------------------------------------------------------------------------

PARSED_ARGUMENTS=$(getopt -an update.sh -o hfbca --long help,flake,buck2,cache,all -- "$@")
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
    -c | --cache)      CACHE=1               ; shift ;;
    -a | --all)        FLAKE=1; BUCK2=1; CACHE=1; shift ;;

    --) shift; break ;;
    *) echo "Unexpected option: $1 - this should not happen." && usage ;;
  esac
done

[ "$FLAKE" = "0" ] && \
  [ "$BUCK2" = "0" ] && \
  [ "$CACHE" = "0" ] && \
  usage

printf "\nUpdating flake=$FLAKE, buck2=$BUCK2, cache=$CACHE\n\n"

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
  r=$(curl -sq https://api.github.com/repos/facebook/buck2/commits/main | jq -r '.sha')
  v=unstable-$(date +"%Y-%m-%d")
  i=$(nix run nixpkgs#nix-prefetch-git -- --quiet --url https://github.com/facebook/buck2 --rev "$r")
  h=$(echo "$i" | jq -r '.sha256' | xargs nix hash to-sri --type sha256)
  p=$(echo "$i" | jq -r '.path')

  sed -i 's#rev\s*=\s*".*";#rev = "'"$r"'";#'         "$root/buck/nix/buck2/default.nix"
  sed -i 's#hash\s*=\s*".*";#hash = "'"$h"'";#'       "$root/buck/nix/buck2/default.nix"
  sed -i 's#version\s*=\s*".*";#version = "'"$v"'";#' "$root/buck/nix/buck2/default.nix"

  # upstream doesn't have their own Cargo.lock file, so we need to generate one
  t=$(mktemp -d)
  d="$t/buck2"

  echo "BUCK2: generating new Cargo.lock file"
  cp -r "$p" "$d" && chmod -R +w "$d"
  (cd "$d" && nix run nixpkgs#cargo -- --quiet generate-lockfile)
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

## Step 3: Rebuild and push the cache

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
