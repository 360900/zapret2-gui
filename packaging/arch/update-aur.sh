#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Writes PKGBUILD and .SRCINFO for a release into an AUR checkout.
# Usage: update-aur.sh <version> <source tarball> <aur checkout dir>
# Runs makepkg in an Arch container to generate .SRCINFO.
set -eu
version=$1
tarball=$2
aur=$3
here="$(cd "$(dirname "$0")" && pwd)"

sum="$(sha256sum "$tarball" | cut -d' ' -f1)"
sed -e "s/^pkgver=.*/pkgver=$version/" -e "s/^pkgrel=.*/pkgrel=1/" \
	-e "s/^sha256sums=.*/sha256sums=('$sum')/" "$here/PKGBUILD" > "$aur/PKGBUILD"
cp "$here/zapret2-gui.install" "$aur/zapret2-gui.install"

docker run --rm -v "$aur:/pkg" archlinux:latest sh -c '
	useradd -m builder &&
	cp /pkg/PKGBUILD /pkg/zapret2-gui.install /home/builder/ &&
	cd /home/builder && su builder -c "makepkg --printsrcinfo" > /pkg/.SRCINFO'
