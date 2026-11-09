#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs Zapret2 GUI and zapret2, then opens the app.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
APP_DIR=/opt/zapret2-gui
BIN=/usr/local/bin/zapret2-gui
DESKTOP=/usr/share/applications/zapret2-gui.desktop
ICON=/usr/share/icons/hicolor/scalable/apps/zapret2-gui.svg
POLICY=/usr/share/polkit-1/actions/org.zapret2gui.policy

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mError: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(uname)" = Linux ] || die "only Linux is supported"

if [ "$(id -u)" = 0 ]; then
	SUDO=
else
	command -v sudo >/dev/null 2>&1 || die "sudo is required. Run this script as root instead."
	SUDO=sudo
fi

have() { command -v "$1" >/dev/null 2>&1; }

gui_libs_ok() {
	have python3 && python3 -c '
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
assert (Adw.get_major_version(), Adw.get_minor_version()) >= (1, 2)
' >/dev/null 2>&1
}

missing_deps() {
	gui_libs_ok || echo gui
	for c in curl nft pkexec pgrep; do have "$c" || echo "$c"; done
	have nslookup || have host || echo nslookup
}

install_deps() {
	if have pacman; then
		$SUDO pacman -S --needed --noconfirm python python-gobject gtk4 libadwaita curl nftables polkit procps-ng bind
	elif have apt-get; then
		$SUDO apt-get update
		pk=pkexec
		apt-cache show pkexec >/dev/null 2>&1 || pk=policykit-1
		$SUDO apt-get install -y --no-install-recommends python3 python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 \
			curl nftables "$pk" procps dnsutils
	elif have dnf; then
		$SUDO dnf install -y python3 python3-gobject gtk4 libadwaita curl nftables polkit procps-ng bind-utils
	elif have zypper; then
		$SUDO zypper --non-interactive install python3 python3-gobject python3-gobject-Gdk \
			typelib-1_0-Gtk-4_0 typelib-1_0-Adw-1 curl nftables polkit procps bind-utils
	elif have eopkg; then
		$SUDO eopkg -y install python3 python-gobject libgtk-4 libadwaita curl nftables polkit procps bind-utils
	elif have apk; then
		$SUDO apk add python3 py3-gobject3 gtk4.0 libadwaita curl nftables polkit procps bind-tools
	elif have xbps-install; then
		$SUDO xbps-install -Sy python3 python3-gobject gtk4 libadwaita curl nftables polkit procps-ng bind-utils
	else
		return 1
	fi
}

say "Checking requirements"
if [ -n "$(missing_deps)" ]; then
	say "Installing required packages"
	install_deps || die "could not find a supported package manager. Please install: Python 3 with PyGObject, GTK 4, libadwaita, curl, nftables, polkit, nslookup (bind/dnsutils)"
	[ -z "$(missing_deps)" ] || die "still missing after install: $(missing_deps | xargs)"
fi

say "Installing Zapret2 GUI"
$SUDO install -d -m 755 "$APP_DIR"
$SUDO install -m 755 "$HERE/src/zapret2-gui" "$APP_DIR/zapret2-gui"
$SUDO install -m 755 "$HERE/src/zapret2-gui-helper" "$APP_DIR/zapret2-gui-helper"
$SUDO install -m 755 "$HERE/uninstall.sh" "$APP_DIR/uninstall.sh"
$SUDO install -d -m 755 "$(dirname "$BIN")" "$(dirname "$DESKTOP")" "$(dirname "$ICON")" "$(dirname "$POLICY")"
$SUDO ln -sf "$APP_DIR/zapret2-gui" "$BIN"
$SUDO install -m 644 "$HERE/data/zapret2-gui.desktop" "$DESKTOP"
$SUDO install -m 644 "$HERE/data/zapret2-gui.svg" "$ICON"
$SUDO install -m 644 "$HERE/data/org.zapret2gui.policy" "$POLICY"
have update-desktop-database && $SUDO update-desktop-database -q /usr/share/applications 2>/dev/null || true
have gtk-update-icon-cache && $SUDO gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true

say "Installing and configuring zapret2"
$SUDO "$APP_DIR/zapret2-gui-helper" --plain install || die "zapret2 setup failed. See the messages above."

say "Done. Zapret2 is in your app menu."

# Open the app for the first run, as the desktop user.
if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] && [ "$(id -u)" != 0 ]; then
	say "Opening Zapret2"
	if have setsid; then
		setsid -f "$BIN" >/dev/null 2>&1 </dev/null
	else
		nohup "$BIN" >/dev/null 2>&1 </dev/null &
	fi
else
	echo "Open Zapret2 from your app menu to finish setup."
fi
