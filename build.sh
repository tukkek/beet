#!/usr/bin/bash
# Build script for beet - cross-compiles for amd64 platforms
# Requires: gcc-mingw-w64 for Windows target
set -e

VERSION="${1:-dev}"
BUILD_DIR="build"

echo "=== Building beet v${VERSION} ==="
echo

# Fetch dependencies
echo "Fetching dependencies..."
go mod download

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/linux"
mkdir -p "${BUILD_DIR}/windows"

# Build linux/amd64 (native)
echo "Building for linux/amd64..."
CGO_ENABLED=1 go build \
    -ldflags="-s -w" \
    -o "${BUILD_DIR}/linux/beet" \
    .
./"${BUILD_DIR}/linux/beet" 2>&1 | grep -q "Usage:" && echo "  Self-test: OK"

# Build windows/amd64 if mingw available
if command -v x86_64-w64-mingw32-gcc &>/dev/null; then
    echo "Building for windows/amd64..."
    CGO_ENABLED=1 GOOS=windows GOARCH=amd64 CC=x86_64-w64-mingw32-gcc go build \
        -ldflags="-s -w" \
        -o "${BUILD_DIR}/windows/beet.exe" \
        .
else
    echo "Skipping windows/amd64 (install gcc-mingw-w64)"
fi


# Create zip archive
echo "Creating archive..."
(cd "${BUILD_DIR}" && zip -r beet.zip . >/dev/null)

echo
echo "=== Build complete ==="
find "${BUILD_DIR}" -type f -exec ls -lh {} \;
