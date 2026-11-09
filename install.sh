#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Installs Zapret2 GUI and zapret2, then opens the app.
# Run again to update: the app is replaced and zapret2 is updated to the latest
# release, keeping its config and the method found.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
APP_DIR=/opt/zapret2-gui
BIN=/usr/local/bin/zapret2-gui
DESKTOP=/usr/share/applications/org.zapret2gui.App.desktop
AUTOSTART=/etc/xdg/autostart/zapret2-gui.desktop
ICONS=/usr/share/icons/hicolor/scalable/apps
POLICY=/usr/share/polkit-1/actions/org.zapret2gui.policy

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mError: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(uname)" = Linux ] || die "only Linux is supported"
[ -e /usr/bin/zapret2-gui ] && die "Zapret2 GUI is already installed from a package. Update or remove it with your package manager."

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

# An existing setup made by this app is updated, not reinstalled.
UPDATE=
[ -f /var/lib/zapret2-gui/state.json ] && [ -f /opt/zapret2/config ] && UPDATE=1

# Close a running app so it restarts with the new version.
APP_PATTERN='python3 -I [^ ]*/zapret2-gui( |$)'
pkill -f "$APP_PATTERN" 2>/dev/null || true

if [ -n "$UPDATE" ]; then
	say "Updating Zapret2 GUI"
else
	say "Installing Zapret2 GUI"
fi
$SUDO install -d -m 755 "$APP_DIR"
$SUDO install -m 755 "$HERE/src/zapret2-gui" "$APP_DIR/zapret2-gui"
$SUDO install -m 755 "$HERE/src/zapret2-gui-helper" "$APP_DIR/zapret2-gui-helper"
$SUDO install -m 755 "$HERE/uninstall.sh" "$APP_DIR/uninstall.sh"
$SUDO install -d -m 755 "$(dirname "$BIN")" "$(dirname "$DESKTOP")" "$(dirname "$AUTOSTART")" "$ICONS" "$(dirname "$POLICY")"
$SUDO ln -sf "$APP_DIR/zapret2-gui" "$BIN"
$SUDO rm -f /usr/share/applications/zapret2-gui.desktop
$SUDO install -m 644 "$HERE/data/org.zapret2gui.App.desktop" "$DESKTOP"
$SUDO install -m 644 "$HERE/data/zapret2-gui-autostart.desktop" "$AUTOSTART"
$SUDO install -m 644 "$HERE/data/zapret2-gui.svg" "$ICONS/zapret2-gui.svg"
$SUDO install -m 644 "$HERE/data/zapret2-gui-off.svg" "$ICONS/zapret2-gui-off.svg"
$SUDO install -m 644 "$HERE/data/org.zapret2gui.policy" "$POLICY"
if have update-desktop-database; then
	$SUDO update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi
if have gtk-update-icon-cache; then
	$SUDO gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi

if [ -n "$UPDATE" ]; then
	say "Updating zapret2"
	$SUDO "$APP_DIR/zapret2-gui-helper" --plain update || die "zapret2 update failed. See the messages above."
	say "Done. Zapret2 is up to date."
else
	say "Installing and configuring zapret2"
	$SUDO "$APP_DIR/zapret2-gui-helper" --plain install || die "zapret2 setup failed. See the messages above."
	say "Done. Zapret2 is in your app menu."
fi

# Open the app, as the desktop user.
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
