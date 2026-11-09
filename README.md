# Zapret2 GUI

One-click DPI bypass for Linux. Type the websites that are blocked for you, and Zapret2 GUI sets up [zapret2](https://github.com/bol-van/zapret2), finds a bypass method that works on your connection and keeps it running for all websites and apps.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/welcome-dark.png">
    <img alt="Unblock websites" src="docs/screenshots/welcome-light.png" width="32%">
  </picture>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/working-dark.png">
    <img alt="Looking for a working method" src="docs/screenshots/working-light.png" width="32%">
  </picture>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/home-dark.png">
    <img alt="Unblocking is on" src="docs/screenshots/home-light.png" width="32%">
  </picture>
</p>

- No setup or knowledge needed: zapret2 is installed and configured for your system automatically.
- Finds a working method with zapret2's own `blockcheck2` in its fastest mode.
- Test several websites at once without making the search slower. For blocked apps, enter the website they use.
- Bypass only applies to blocked sites (autohostlist), other sites are not touched.
- Lives in the tray, starts with your computer. On/off from the tray menu.
- Something blocked again? Press **Find** to search for a new method.

## Install

Pick the line for your system. All packages are also on the [releases page](https://github.com/360900/zapret2-gui/releases/latest).

| System | Command |
|---|---|
| Arch, CachyOS, Manjaro, EndeavourOS | `sudo pacman -U https://github.com/360900/zapret2-gui/releases/latest/download/zapret2-gui.pkg.tar.zst` |
| Debian 12+, Ubuntu 24.04+, Mint 22+, Pop!_OS | `curl -LO https://github.com/360900/zapret2-gui/releases/latest/download/zapret2-gui.deb && sudo apt install ./zapret2-gui.deb` |
| Fedora, RHEL 10, Alma, Rocky | `sudo dnf install https://github.com/360900/zapret2-gui/releases/latest/download/zapret2-gui.rpm` |
| openSUSE Tumbleweed | `sudo zypper install --allow-unsigned-rpm https://github.com/360900/zapret2-gui/releases/latest/download/zapret2-gui.rpm` |
| Alpine | `wget https://github.com/360900/zapret2-gui/releases/latest/download/zapret2-gui.apk && doas apk add --allow-untrusted zapret2-gui.apk` |
| Anything else | [install script](#install-script) |

Then open **Zapret2** from your app menu. On first start it asks for your password once to download and set up zapret2.

### Install script

Works on any distro with apt, pacman, dnf, zypper, eopkg, apk or xbps. Installs the dependencies, sets up zapret2 and opens the app.

```sh
git clone https://github.com/360900/zapret2-gui.git
cd zapret2-gui
./install.sh
```

Or download `zapret2-gui-<version>.tar.gz` from the releases page, unpack it and run `./install.sh`.

### Update

- **Packages**: run the install command for your system again to get the latest release.
- **Install script**: run `git pull && ./install.sh` again.
- **zapret2 itself**: choose **Update zapret2** in the app menu. The install script does this automatically.

Updating keeps your settings, websites and the method found. If a new zapret2 no longer accepts the saved method, the app asks you to find a new one.

### Requirements

- Linux with systemd or OpenRC
- GTK 4 and libadwaita 1.2 or newer
- Python 3, curl, nftables (or iptables), polkit, nslookup

Packages and the install script pull these in automatically.

## Use

1. Type a website that does not open for you. Press **Add another website** for more. For a blocked app, type the website it uses, like `discord.com`.
2. Press **Find a working method** and wait a few minutes.
3. Done. Blocked websites and apps work normally.

Closing the window keeps Zapret2 in the tray, and it starts there when you log in. Click the tray icon to open it, right-click for the on/off switch, a new search, or **Quit**. Unblocking itself is a system service, so it keeps working even when the app is closed.

If something stops working later, press **Find** to search again.

The tray needs a desktop with tray support: KDE Plasma, Cinnamon, XFCE, Budgie, LXQt and most others. On GNOME, install the [AppIndicator extension](https://extensions.gnome.org/extension/615/appindicator-support/) (Ubuntu has it by default). Without a tray, closing the window quits the app. To stop it starting at login, turn it off in your desktop's autostart settings or delete `/etc/xdg/autostart/zapret2-gui.desktop`.

## Uninstall

Uninstalling also stops and removes zapret2 and its firewall rules. Dependencies are kept.

| Installed with | Command |
|---|---|
| pacman | `sudo pacman -R zapret2-gui` |
| deb | `sudo apt remove zapret2-gui` |
| rpm | `sudo dnf remove zapret2-gui` or `sudo zypper remove zapret2-gui` |
| apk | `doas apk del zapret2-gui` |
| Install script | `./uninstall.sh` or `/opt/zapret2-gui/uninstall.sh` |

## How it works

- **Updating zapret2** replaces it with the latest release but keeps its config, host lists and custom scripts, the same files `install_easy.sh` offers to keep, then runs `install_easy.sh` again. The saved method is checked with the new `nfqws2 --dry-run` first.
- **Setup** downloads the latest zapret2 release, verifies its binaries against the release checksums and runs zapret2's `install_easy.sh` with every answer preset: nfqws2 on, autohostlist filtering, firewall type detected by zapret2, IPv6 only if it works, no list downloads, no flow offloading.
- **Finding a method** pauses zapret2 and runs `blockcheck2.sh` in batch mode at the `veryquick` scan level against HTTPS (TLS 1.2, then TLS 1.3 if nothing works). It only runs for the first website that is actually blocked, so extra websites don't slow it down. Each method found is then applied to zapret2 and checked against all websites in parallel; the first one that opens all of them is kept, otherwise the one that opens the most. The websites are added to zapret2's user host list. HTTP and QUIC keep zapret2's default methods.
- **Cancel**, or closing the window, stops the test and restores the previous settings.
- Root actions run through `pkexec` and one helper, `zapret2-gui-helper`. The GUI itself never runs as root.

| Path | What |
|---|---|
| `/opt/zapret2` | zapret2, config in `/opt/zapret2/config` |
| `/opt/zapret2-gui` | the app and its root helper |
| `/var/lib/zapret2-gui/state.json` | chosen method and websites |
| `/etc/xdg/autostart/zapret2-gui.desktop` | starts the app in the tray at login |
| `/usr/share/polkit-1/actions/org.zapret2gui.policy` | password prompt rules |

## Troubleshooting

- **"Nothing to unblock"**: the websites opened without help. Enter one that does not open for you.
- **"No working method found"**: your provider likely blocks the site by IP address. zapret2 cannot bypass that, a VPN can.
- **DNS warning**: your provider may tamper with DNS answers. Turn on secure DNS (DNS over HTTPS) in your browser or system.
- **"Still not opening"** under the status: the method works for your other websites but not for these. Press **Find** with only those websites to look for a method for them.
- **More detail**: the working screen has a **Details** section with the full zapret2 output.

## Development

```
src/zapret2-gui            GTK 4 / libadwaita app with tray icon (Python)
src/zapret2-gui-helper     root helper: install, update, blockcheck, enable, disable, uninstall
data/                      desktop and autostart entries, icons, polkit policy
install.sh, uninstall.sh   script install for any distro
packaging/nfpm.yaml        deb, rpm, Arch and Alpine packages
packaging/arch/            PKGBUILD and AUR update script
packaging/build.sh         builds dist/: source tarball, packages, SHA256SUMS
packaging/test-package.sh  installs, checks and removes a package in a distro container
.github/workflows/ci.yml   lint, build, test on 7 distros, release
```

Build all packages (uses [nfpm](https://nfpm.goreleaser.com), or its Docker image if nfpm is not installed):

```sh
packaging/build.sh
```

Test a package in a clean container:

```sh
docker run --rm -v "$PWD/dist:/dist:ro" -v "$PWD/packaging:/p:ro" fedora:latest sh /p/test-package.sh rpm-dnf /dist
```

The helper also runs on its own as root, for example `sudo src/zapret2-gui-helper --plain blockcheck example.com discord.com`.

### Releasing

1. Set `VERSION` in `src/zapret2-gui` and commit.
2. Tag and push: `git tag v1.2.3 && git push origin main v1.2.3`.

CI checks that the tag matches `VERSION`, builds and tests every package, and publishes the GitHub release.

## Credits

- [zapret2](https://github.com/bol-van/zapret2) by bol-van does the actual bypassing.
- The UI follows the [oneDesign](https://github.com/360900/oneDesign) design language.

## License

GPL-3.0-or-later
