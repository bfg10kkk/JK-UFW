#!/bin/sh
# jk-ufw: put the "Guest Network" page, the crimson guest login page and the dashboard widget onto a running
# firewall for testing, without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-guest.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-guest.sh
#   sh /tmp/try-guest.sh                                  # files from stable/26.7
#   sh /tmp/try-guest.sh claude/project-thread-gzxmp2     # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-guest.sh --remove   (page, menu entry and widget; "opnsense-revert core" restores everything)
# The guest network itself is removed on the page with "Удалить гостевую сеть", before running --remove.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/CaptivePortal/GuestController.php
mvc/app/views/OPNsense/CaptivePortal/guest.volt
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
scripts/captiveportal/htdocs_default/index.html
scripts/captiveportal/htdocs_default/css/signin.css
www/js/widgets/Metadata/JkUfw.xml
www/js/widgets/JkUfwCommon.js
www/js/widgets/JkUfwOverview.js
www/js/widgets/JkUfwTraffic.js
www/js/widgets/JkUfwClients.js
www/js/widgets/JkUfwInternet.js
www/js/widgets/JkUfwSecurity.js
www/js/widgets/JkUfwDns.js
www/js/widgets/JkUfwSystem.js
www/js/widgets/JkUfwPorts.js
www/js/widgets/JkUfwServices.js
www/js/widgets/JkUfwVpn.js
www/js/widgets/JkUfwGuest.js
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -f "$BASE/mvc/app/controllers/OPNsense/CaptivePortal/GuestController.php" \
          "$BASE/mvc/app/views/OPNsense/CaptivePortal/guest.volt" \
          "$BASE/www/js/widgets/JkUfwGuest.js"
    # the menu file may also carry other jk-ufw entries; drop only ours
    if [ -f "$BASE/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml" ]; then
        sed -i '' '/ui\/captiveportal\/guest/d' "$BASE/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml"
    fi
    clear_caches
    echo "Removed. The crimson login page stays; 'opnsense-revert core' brings back the stock one."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-guest.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FILES; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
for f in $FILES; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
clear_caches
# zones copy the default login page when the portal starts
if configctl captiveportal status 2>/dev/null | grep -q running; then
    configctl captiveportal restart >/dev/null
fi

echo
echo "Done. Open https://<firewall>/ui/captiveportal/guest"
echo "(menu: Services > Captive Portal > Guest Network)"
echo "Dashboard: + Add widget > 'jk-ufw: Гостевая сеть'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
