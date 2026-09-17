#!/bin/bash
set -e

BUILD_TOP="${ANDROID_BUILD_TOP:-$(pwd)}"
DEVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_DIR="$DEVICE_DIR/patches"

CORE_DIR="$BUILD_TOP/system/core"
COMPAT_DIR="$BUILD_TOP/hardware/lineage/compat"

apply_patch() {
    local target_dir="$1"
    local patch_file="$2"
    local patch_name="$3"

    if [ ! -d "$target_dir" ]; then
        echo "[apply_patches] Target directory $target_dir does not exist. Skipping $patch_name."
        return 0
    fi

    if [ ! -f "$patch_file" ]; then
        echo "[apply_patches] Patch $patch_file does not exist. Skipping $patch_name."
        return 0
    fi

    if git -C "$target_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
        echo "[apply_patches] $patch_name already applied. Skipping."
    elif git -C "$target_dir" apply --check "$patch_file" >/dev/null 2>&1; then
        echo "[apply_patches] Applying $patch_name in $(basename "$target_dir")..."
        git -C "$target_dir" apply "$patch_file"
    else
        echo "[apply_patches] WARNING: $patch_name could not be applied cleanly."
    fi
}

echo "=== Applying ROM Source Patches for Ruby/Rubyx ==="

# 1. system/core patches
apply_patch "$CORE_DIR" "$PATCHES_DIR/libutils.patch" "libutils patch"
apply_patch "$CORE_DIR" "$PATCHES_DIR/libfs_avb.patch" "libfs_avb AVB unlock patch"

# 2. hardware/lineage/compat patch
apply_patch "$COMPAT_DIR" "$PATCHES_DIR/hardware_lineage_compat.patch" "hardware/lineage/compat patch"

# 3. Copy VNDK prebuilts if not present in compat
if [ -d "$COMPAT_DIR" ] && [ -d "$PATCHES_DIR/vndk/v34" ]; then
    mkdir -p "$COMPAT_DIR/vndk/v34/arm" "$COMPAT_DIR/vndk/v34/arm64"
    if [ ! -f "$COMPAT_DIR/vndk/v34/arm/libtinyxml2-v34.so" ]; then
        echo "[apply_patches] Installing libtinyxml2-v34.so (arm)..."
        cp "$PATCHES_DIR/vndk/v34/arm/libtinyxml2-v34.so" "$COMPAT_DIR/vndk/v34/arm/"
    fi
    if [ ! -f "$COMPAT_DIR/vndk/v34/arm64/libtinyxml2-v34.so" ]; then
        echo "[apply_patches] Installing libtinyxml2-v34.so (arm64)..."
        cp "$PATCHES_DIR/vndk/v34/arm64/libtinyxml2-v34.so" "$COMPAT_DIR/vndk/v34/arm64/"
    fi
fi

echo "=== All patches checked/applied successfully ==="
