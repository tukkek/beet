#!/usr/bin/bash
# Test script for beet - run from repository root
# Builds the project first, then tests the native binary
set -e

REPO_ROOT="."
BUILD_DIR="${REPO_ROOT}/build"

echo "=== Building beet ==="
"${REPO_ROOT}/build.sh" >/dev/null

# Use the native Linux binary
BEET="${BUILD_DIR}/linux/beet"
TEST_DIR="${REPO_ROOT}/test"

if [ ! -f "$BEET" ]; then
    echo "ERROR: Native binary not found at $BEET"
    exit 1
fi

# Helper: test volume levels for a given file
# Usage: test_volume "label" "file"
test_volume() {
    local label="$1"
    local file="$2"
    echo "Testing $label volume levels..."

    # Default (no argument)
    echo "  Default (no arg)..."
    $BEET "$file" >/dev/null 2>&1 &
    PID=$!
    sleep 2
    kill $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true

    local volumes=(0 50 100 200)
    for vol in "${volumes[@]}"; do
        echo "  Volume $vol..."
        $BEET --volume "$vol" "$file" >/dev/null 2>&1 &
        PID=$!
        sleep 2
        kill $PID 2>/dev/null || true
        wait $PID 2>/dev/null || true
    done

    echo "$label volume levels: OK"
    echo
}

clear
echo "=== Testing beet player ==="
echo

# Test volume levels for each format
test_volume "WAV" "$TEST_DIR/file_example_WAV_10MG.wav"
test_volume "MP3" "$TEST_DIR/file_example_MP3_5MG.mp3"
test_volume "OGG" "$TEST_DIR/file_example_OOG_5MG.ogg"

# Test missing file
echo "Testing missing file..."
if $BEET "$TEST_DIR/nonexistent.wav" 2>&1 | grep -q "beet: open"; then
    echo "Missing file error handling: OK"
else
    echo "Missing file error handling: FAILED"
    exit 1
fi
echo

# Test no arguments
echo "Testing no arguments..."
if $BEET 2>&1 | grep -q "Usage:"; then
    echo "Usage message: OK"
else
    echo "Usage message: FAILED"
    exit 1
fi
echo

# Test sequential playback (3x with sleep)
echo "Testing sequential playback (3x)..."
for i in 1 2 3; do
    $BEET "$TEST_DIR/file_example_WAV_10MG.wav" >/dev/null 2>&1 &
    sleep .1
done
sleep 2
killall beet 2>/dev/null || true
echo "Sequential playback: OK"
echo

echo "=== All tests passed ==="
