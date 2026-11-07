#!/bin/sh
# jk-ufw: put the new first-setup wizard onto a running firewall for testing, without rebuilding the image.
# Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-setup.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-setup.sh
#   sh /tmp/try-setup.sh                      # files from stable/26.7
#   sh /tmp/try-setup.sh <branch>             # or from another branch, e.g. one under review
#
# Then open https://<firewall>/ui/core/initial_setup (menu: System > Wizard).
# The classic wizard stays at /ui/core/initial_setup?classic
# Undo: sh /tmp/try-setup.sh --remove
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
CTRL=mvc/app/controllers/OPNsense/Core/InitialSetupController.php
VIEW=mvc/app/views/OPNsense/Core/jkufw_setup.volt

if [ "$BRANCH" = "--remove" ]; then
    if [ -f "$BASE/$CTRL.jkufw-orig" ]; then
        mv -f "$BASE/$CTRL.jkufw-orig" "$BASE/$CTRL"
    fi
    rm -f "$BASE/$VIEW"
    echo "Removed, the stock wizard is back."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-setup.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $CTRL $VIEW; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
if [ ! -f "$BASE/$CTRL.jkufw-orig" ]; then
    cp -p "$BASE/$CTRL" "$BASE/$CTRL.jkufw-orig"
fi
for f in $CTRL $VIEW; do
    install -m 0644 "$TMP/$f" "$BASE/$f"
done

echo
echo "Done. Open https://<firewall>/ui/core/initial_setup  (System > Wizard)"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
