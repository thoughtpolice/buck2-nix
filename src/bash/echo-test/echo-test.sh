echo hello world
echo "args:"
for x in "$@"; do
    echo "  $x"
done
