#!/bin/sh
# jk-ufw: put the "Remote Access" page (one-click WireGuard VPN with QR codes) onto a running firewall
# for testing, without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-vpn.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-vpn.sh
#   sh /tmp/try-vpn.sh                                  # files from stable/26.7
#   sh /tmp/try-vpn.sh claude/project-thread-x8aukv     # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-vpn.sh --remove   (or reinstall core: opnsense-revert core)
# The VPN instance, peers and rules the page created stay; delete them on VPN > WireGuard and Firewall pages.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/Wireguard/RemoteController.php
mvc/app/views/OPNsense/Wireguard/remote.volt
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
www/js/widgets/JkUfwVpn.js
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -f "$BASE/mvc/app/controllers/OPNsense/Wireguard/RemoteController.php" \
          "$BASE/mvc/app/views/OPNsense/Wireguard/remote.volt"
    # the menu file may also carry other jk-ufw entries; keep it unless only ours is in it
    if [ -f "$BASE/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml" ] && \
       [ "$(grep -c 'url=' "$BASE/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml")" = "1" ]; then
        rm -rf "$BASE/mvc/app/models/OPNsense/JkUfw"
    fi
    clear_caches
    echo "Removed."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-vpn.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FILES; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
MENU=mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
if [ -f "$BASE/$MENU" ] && grep -q '/ui/ids/threats' "$BASE/$MENU" && ! grep -q '/ui/ids/threats' "$TMP/$MENU"; then
    # try-ids.sh from an unmerged branch put the IDS entry there; keep both entries
    cat > "$TMP/$MENU" <<'XML'
<menu>
    <!-- jk-ufw additions, kept in their own file so upstream menu changes merge cleanly -->
    <Services>
        <IDS>
            <Threats VisibleName="Threat Management" order="5" url="/ui/ids/threats"/>
        </IDS>
    </Services>
    <VPN>
        <WireGuard>
            <RemoteAccess VisibleName="Remote Access" order="5" url="/ui/wireguard/remote"/>
        </WireGuard>
    </VPN>
</menu>
XML
fi
for f in $FILES; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
clear_caches

echo
echo "Done. Open https://<firewall>/ui/wireguard/remote"
echo "(menu: VPN > WireGuard > Remote Access)"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
