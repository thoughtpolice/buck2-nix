#!/usr/bin/env bash
# SPDX-FileCopyrightText: © 2022 Austin Seipp
# SPDX-License-Identifier: MIT OR Apache-2.0

# [tag:cache-upload-script] This script needs to work both from the developer command line
# and also from within the context of a post-build-hook in Nix, which is rather austere.

cache_upload() {
  # NOTE: DO NOT MODIFY THIS FUNCTION WITHOUT TESTING IT. It is the only codepath used when
  # uploading to the cache from within the context of a post-build-hook in Nix, and used as well
  # when ordinary users do it. Because it must work in both contexts, the code is a bit more
  # 'careful' than it would be otherwise.
  set -e; set -f; export IFS=' '
  [[ -z "$OUT_PATHS" ]] && echo "no out paths provided" && exit 1

  tsbin="/nix/var/nix/profiles/default/bin/ts"
  user=${USER:-root}
  [[ ! -f "$tsbin" ]] && tsbin="/nix/var/nix/profiles/per-user/$user/profile/bin/ts"
  [[ ! -f "$tsbin" ]] && echo "no task spooler installed! exiting" && exit 2

  export S3_BUCKET="${S3_BUCKET:-__S3_BUCKET__}"
  export S3_ENDPOINT="${S3_ENDPOINT:-__S3_ENDPOINT__}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-__AWS_ACCESS_KEY_ID__}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-__AWS_SECRET_ACCESS_KEY__}"

  [ $S3_BUCKET == "__S3_BUCKET__" ] && echo "S3_BUCKET not set, exiting" && exit 3
  [ $S3_ENDPOINT == "__S3_ENDPOINT__" ] && echo "S3_ENDPOINT not set, exiting" && exit 4
  [ $AWS_ACCESS_KEY_ID == "__AWS_ACCESS_KEY_ID__" ] && echo "AWS_ACCESS_KEY_ID not set, exiting" && exit 5
  [ $AWS_SECRET_ACCESS_KEY == "__AWS_SECRET_ACCESS_KEY__" ] && echo "AWS_SECRET_ACCESS_KEY not set, exiting" && exit 6

  echo "Uploading paths" $DRV_PATH " " $OUT_PATHS
    $tsbin /nix/var/nix/profiles/default/bin/nix copy \
      --to "s3://$S3_BUCKET?write-nar-listing=1&index-debug-info=1&compression=zstd&scheme=https&endpoint=$S3_ENDPOINT" \
      $DRV_PATH $OUT_PATHS
}

# This manual path is used when we want to upload a bunch of paths to the cache,
# but we don't use CI to do it. For example, if we're rebuilding the world due
# to a glibc bump, etc. This is normally called from upload.sh, but it will work
# here if you hold its hand correctly with the right environment variables.
if [[ ! -z "$MANUAL_REBUILD_AND_PUSH" ]]; then
  # manual path. see: https://www.haskellforall.com/2022/10/how-to-correctly-cache-build-time.html
  mapfile -t TARGETS < <(nix build --no-link --print-out-paths ./buck/nix#attrs | xargs cat | xargs printf './buck/nix#%s\n')
  mapfile -t BUILDS < <(echo "${TARGETS[@]}" | xargs nix build --print-out-paths --no-link)
  mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --json | jq -r '.[] | .deriver')
  mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)

  for OUT_PATHS in "${DEPENDENCIES[@]}"; do cache_upload; done
  exit 0
fi

cache_upload
