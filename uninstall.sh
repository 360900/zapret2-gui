#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Removes Zapret2 GUI and zapret2 completely.
set -u

APP_DIR=/opt/zapret2-gui
HELPER="$APP_DIR/zapret2-gui-helper"

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }

if [ "$(id -u)" = 0 ]; then
	SUDO=
else
	SUDO=sudo
fi

say "Closing Zapret2"
pkill -f 'python3 -I [^ ]*/zapret2-gui$' 2>/dev/null

say "Removing zapret2"
if [ -x "$HELPER" ]; then
	$SUDO "$HELPER" --plain uninstall || echo "zapret2 removal reported a problem, continuing"
elif [ -d /opt/zapret2 ]; then
	[ -f /opt/zapret2/uninstall_easy.sh ] && $SUDO sh /opt/zapret2/uninstall_easy.sh </dev/null
	$SUDO rm -rf /opt/zapret2
fi

say "Removing Zapret2 GUI"
$SUDO rm -f /usr/local/bin/zapret2-gui \
	/usr/share/applications/zapret2-gui.desktop \
	/usr/share/icons/hicolor/scalable/apps/zapret2-gui.svg \
	/usr/share/polkit-1/actions/org.zapret2gui.policy \
	/run/zapret2-gui.lock
$SUDO rm -rf "$APP_DIR" /var/lib/zapret2-gui
command -v update-desktop-database >/dev/null 2>&1 && $SUDO update-desktop-database -q /usr/share/applications 2>/dev/null
command -v gtk-update-icon-cache >/dev/null 2>&1 && $SUDO gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null

say "Zapret2 has been removed"
