VOLDIR="/root/volumes"

worker_fuse="worker"
fuse_dir_to_unmount="$VOLDIR/${worker_fuse}/build"

set -x
sudo fusermount -u "$fuse_dir_to_unmount" && sleep 1 || true
sudo rm -rf bb "$VOLDIR/${worker_fuse}"
mkdir -p "$VOLDIR"
mkdir -m 0777 "$VOLDIR/${worker_fuse}" "$VOLDIR/${worker_fuse}"/{build,cas,cas/persistent_state}
mkdir -m 0700 "$VOLDIR/${worker_fuse}/cache"
mkdir -m 0700 -p $VOLDIR/storage-{ac,cas}-{0,1}/persistent_state
set +x

cleanup() {
    EXIT_STATUS=$?
    set -x
    sudo fusermount -u "$fuse_dir_to_unmount" || true
    exit $EXIT_STATUS
}

# If no arguments have been given, automatically unmount worker FUSE mount.
# This avoids annoying problems when trying to cleanup after a simple test run of Buildbarn.
if [ $# -eq 0 ]; then
    echo "Registering automatic unmount for $fuse_dir_to_unmount"
    trap cleanup EXIT
else
    echo "When finished, manually unmount $fuse_dir_to_unmount"
fi
docker compose up "$@"
