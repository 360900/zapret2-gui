#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs a built package in a clean distro container, checks it, removes it.
# Run inside the container: test-package.sh <deb|rpm-dnf|rpm-zypper|arch|apk> <dist dir>
set -eu
kind=$1
dist=$2

case $kind in
	deb)
		export DEBIAN_FRONTEND=noninteractive
		apt-get update -q
		apt-get install -y -q "$dist/zapret2-gui.deb"
		;;
	rpm-dnf)
		dnf install -y -q "$dist/zapret2-gui.rpm"
		;;
	rpm-zypper)
		zypper --non-interactive --no-gpg-checks install --allow-unsigned-rpm "$dist/zapret2-gui.rpm"
		;;
	arch)
		pacman -Sy --noconfirm
		pacman -U --noconfirm "$dist/zapret2-gui.pkg.tar.zst"
		;;
	apk)
		apk add --allow-untrusted "$dist/zapret2-gui.apk"
		;;
	*)
		echo "unknown kind $kind" >&2
		exit 2
		;;
esac

echo "== checking installed files"
for f in /usr/bin/zapret2-gui /opt/zapret2-gui/zapret2-gui /opt/zapret2-gui/zapret2-gui-helper \
	/usr/share/applications/org.zapret2gui.App.desktop /etc/xdg/autostart/zapret2-gui.desktop \
	/usr/share/icons/hicolor/scalable/apps/zapret2-gui.svg /usr/share/icons/hicolor/scalable/apps/zapret2-gui-off.svg \
	/usr/share/polkit-1/actions/org.zapret2gui.policy; do
	[ -e "$f" ] || { echo "missing $f" >&2; exit 1; }
done
for c in curl nft pkexec pgrep nslookup; do
	command -v "$c" >/dev/null || { echo "missing command $c" >&2; exit 1; }
done

echo "== checking GUI libraries"
python3 -I - <<'PY'
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk
v = (Adw.get_major_version(), Adw.get_minor_version())
assert v >= (1, 2), v
print("gtk", Gtk.get_major_version(), Gtk.get_minor_version(), "adw", *v)
PY
python3 -I -c "import ast; ast.parse(open('/opt/zapret2-gui/zapret2-gui').read()); ast.parse(open('/opt/zapret2-gui/zapret2-gui-helper').read())"
/opt/zapret2-gui/zapret2-gui-helper 2>&1 | grep -q "Privileged helper" || { echo "helper does not run" >&2; exit 1; }

echo "== removing"
case $kind in
	deb) apt-get remove -y -q zapret2-gui ;;
	rpm-dnf) dnf remove -y -q zapret2-gui ;;
	rpm-zypper) zypper --non-interactive remove zapret2-gui ;;
	arch) pacman -R --noconfirm zapret2-gui ;;
	apk) apk del zapret2-gui ;;
esac
[ ! -e /opt/zapret2-gui/zapret2-gui ] || { echo "files left after removal" >&2; exit 1; }
echo "== OK"
