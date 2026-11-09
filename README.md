# Zapret2 GUI

One-click DPI bypass for Linux, built on [zapret2](https://github.com/bol-van/zapret2).

## Install

```sh
./install.sh
```

Installs the dependencies, downloads the latest zapret2 release, configures it for your system and opens the app. Type a website that is blocked for you and press **Find a working method**.

If websites get blocked again later, open Zapret2 and press **Find**.

## Uninstall

```sh
./uninstall.sh
```

Removes the app and zapret2 completely. Packages installed as dependencies are kept.

## How it works

- Setup runs zapret2's `install_easy.sh` with every answer preset: nfqws2 on, autohostlist filtering, firewall type autodetected, IPv6 on only when it works, no list downloads.
- Finding a method runs `blockcheck2.sh` in batch mode at the `veryquick` scan level against HTTPS (TLS 1.2, then TLS 1.3 if nothing works). The first method that also opens the site through the real service is kept.
- Root actions go through `pkexec` and a single helper in `/opt/zapret2-gui`.

Requires systemd or OpenRC, GTK 4 and libadwaita 1.2 or newer.

## License

GPL-3.0-or-later
