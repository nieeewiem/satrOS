#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_root="${SATROS_BUILD_ROOT:-${TMPDIR:-/tmp}/satros-build}"
pkg_dest="${build_root}/packages"
pkg_build="${build_root}/package-build"
src_dest="${build_root}/sources"
pacman_cache="${SATROS_PACMAN_CACHE:-${build_root}/pacman-cache}"
local_repo="${build_root}/local-repo"
work_dir="${build_root}/work"
output_dir="${SATROS_OUTPUT_DIR:-${build_root}/out}"
pacman_conf="${build_root}/pacman.conf"

mkdir -p "$pkg_dest" "$pkg_build" "$src_dest" "$pacman_cache" "$local_repo" "$output_dir"

BUILDDIR="$pkg_build" \
PKGDEST="$pkg_dest" \
SRCDEST="$src_dest" \
makepkg --nodeps --noconfirm --cleanbuild \
    --dir "$repo_dir/packaging/calamares-bin" -p PKGBUILD -f

calamares_pkg="$(find "$pkg_dest" -maxdepth 1 -type f -name 'calamares-*.pkg.tar.zst' -print -quit)"
if [[ -z "$calamares_pkg" ]]; then
    printf '%s\n' 'error: local Calamares package was not produced' >&2
    exit 1
fi

cp -- "$calamares_pkg" "$local_repo/"
repo-add "$local_repo/satros-local.db.tar.gz" "$local_repo/$(basename -- "$calamares_pkg")"

awk -v cache="$pacman_cache" -v local_repo="$local_repo" '
    /^\[options\]$/ {
        print
        print "CacheDir = " cache
        next
    }
    /^\[core\]$/ {
        print "[satros-local]"
        print "SigLevel = Optional TrustAll"
        print "Server = file://" local_repo
        print
        next
    }
    { print }
' "$repo_dir/pacman.conf" > "$pacman_conf"

mkarchiso -v -C "$pacman_conf" -w "$work_dir" -o "$output_dir" "$repo_dir"
