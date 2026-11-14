#!/bin/sh
# jk-ufw: put every new page, the setup wizard and all dashboard widgets onto a running firewall for testing,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-all.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-all.sh
#   sh /tmp/try-all.sh                 # everything from stable/26.7
#   sh /tmp/try-all.sh <branch>        # or from another branch
#   sh /tmp/try-all.sh --remove        # take everything out again
#
# It only runs the per-feature scripts (jk-ufw/features/try-*.sh) one after another, so each feature
# can still be installed or removed on its own.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
SRC="$BRANCH"
[ "$BRANCH" = "--remove" ] && SRC="${2:-stable/26.7}"
FEATURES="ids devices vpn geoblock parental notify guest setup sdwan"

TMP=$(mktemp -d /tmp/jkufw-all.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FEATURES; do
    fetch -q -o "$TMP/try-$f.sh" "$REPO/$SRC/jk-ufw/features/try-$f.sh" \
        || { echo "!!! cannot download try-$f.sh from branch $SRC"; exit 1; }
done

if [ "$BRANCH" = "--remove" ]; then
    ORDER=""
    for f in $FEATURES; do ORDER="$f $ORDER"; done
    for f in $ORDER; do
        echo ">>> removing: $f"
        sh "$TMP/try-$f.sh" --remove || echo "!!! $f: removal reported an error, continuing"
    done
    rm -f /usr/local/opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml \
          /usr/local/opnsense/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml \
          /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
    echo
    echo "All jk-ufw features removed."
    exit 0
fi

for f in $FEATURES; do
    echo ">>> installing: $f"
    sh "$TMP/try-$f.sh" "$BRANCH"
done

echo
echo "All done. New pages:"
echo "  Threat Management (IDS/IPS)  /ui/ids/threats"
echo "  Devices                      /ui/jkufw/devices"
echo "  VPN remote access            /ui/wireguard/remote"
echo "  Country blocking             /ui/firewall/geoblock"
echo "  Content filter               /ui/jkufw/parental"
echo "  Telegram notifications       /ui/jkufw/notify"
echo "  Guest network                /ui/captiveportal/guest"
echo "  Setup wizard                 /ui/core/initial_setup"
echo "  SD-WAN (several providers)   /ui/jkufw/sdwan"
echo "Dashboard: + Add widget, the jk-ufw widgets are at the top of the list."
