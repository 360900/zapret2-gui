#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Builds the release tarball and native packages into dist/.
# Uses nfpm from PATH, or its Docker image when nfpm is not installed.
set -eu

cd "$(dirname "$0")/.."
VERSION="$(sed -n 's/^VERSION = "\(.*\)"$/\1/p' src/zapret2-gui)"
[ -n "$VERSION" ] || { echo "VERSION not found in src/zapret2-gui" >&2; exit 1; }
export VERSION

rm -rf dist
mkdir -p dist

# Source tarball for install.sh (also the AUR source).
git archive --format=tar.gz --prefix="zapret2-gui-$VERSION/" -o "dist/zapret2-gui-$VERSION.tar.gz" HEAD

run_nfpm() {
	if command -v nfpm >/dev/null 2>&1; then
		command nfpm "$@"
	else
		docker run --rm -u "$(id -u):$(id -g)" -e VERSION -v "$PWD:/work" -w /work goreleaser/nfpm:latest "$@"
	fi
}

for p in deb rpm archlinux apk; do
	case $p in
		deb) out=zapret2-gui.deb ;;
		rpm) out=zapret2-gui.rpm ;;
		archlinux) out=zapret2-gui.pkg.tar.zst ;;
		apk) out=zapret2-gui.apk ;;
	esac
	run_nfpm package -f packaging/nfpm.yaml -p "$p" -t "dist/$out"
done

(cd dist && sha256sum -- * > SHA256SUMS)
echo "Built $VERSION:"
cat dist/SHA256SUMS
