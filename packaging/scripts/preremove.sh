#!/bin/sh
# Remove zapret2 together with the package, but not on upgrades.
# deb passes "remove" or "upgrade"; rpm passes the number of installs left
# (0 = erase). pacman (old version) and apk only run this on removal.
case "${1:-}" in
	upgrade|failed-upgrade|deconfigure) exit 0 ;;
	*[!0-9]*|'') ;;
	0) ;;
	*) exit 0 ;;
esac
pkill -f 'python3 -I [^ ]*/zapret2-gui$' 2>/dev/null || true
if [ -x /opt/zapret2-gui/zapret2-gui-helper ]; then
	/opt/zapret2-gui/zapret2-gui-helper --plain uninstall || true
fi
exit 0
