#!/bin/sh
# jk-ufw: put the "Content Filter" page (DNS filtering + parental control schedules) and its dashboard widget
# onto a running firewall for testing, without rebuilding the image. Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-parental.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-parental.sh
#   sh /tmp/try-parental.sh                                 # files from stable/26.7
#   sh /tmp/try-parental.sh claude/project-thread-acni2e    # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-parental.sh --remove   (first delete the devices on the page, so their rules go away too)
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

BRANCH="${1:-stable/26.7}"
REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BASE=/usr/local/opnsense
FILES="
mvc/app/controllers/OPNsense/JkUfw/ParentalController.php
mvc/app/controllers/OPNsense/JkUfw/Api/ParentalController.php
mvc/app/models/OPNsense/JkUfw/Parental.php
mvc/app/models/OPNsense/JkUfw/Parental.xml
mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml
mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml
mvc/app/views/OPNsense/JkUfw/parental.volt
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
www/js/widgets/JkUfwParental.js
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

if [ "$BRANCH" = "--remove" ]; then
    rm -f "$BASE/mvc/app/controllers/OPNsense/JkUfw/ParentalController.php" \
          "$BASE/mvc/app/controllers/OPNsense/JkUfw/Api/ParentalController.php" \
          "$BASE/mvc/app/models/OPNsense/JkUfw/Parental.php" \
          "$BASE/mvc/app/models/OPNsense/JkUfw/Parental.xml" \
          "$BASE/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml" \
          "$BASE/mvc/app/views/OPNsense/JkUfw/parental.volt" \
          "$BASE/www/js/widgets/JkUfwParental.js"
    clear_caches
    echo "Removed. Rules marked [jk-ufw] in Firewall > Rules stay until you delete them there."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-parental.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FILES; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/opnsense/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
for f in $FILES; do
    if [ "$f" = "mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml" ] && [ -f "$BASE/$f" ] && ! grep -q ContentFilter "$BASE/$f"; then
        # another jk-ufw feature (e.g. Threat Management) already put its menu entries here: add ours to them
        php -r '$s = file_get_contents($argv[1]); file_put_contents($argv[1], str_replace("</menu>", "    <Firewall>\n        <ContentFilter VisibleName=\"Content Filter\" order=\"45\" url=\"/ui/jkufw/parental\" cssClass=\"fa fa-child fa-fw\"/>\n    </Firewall>\n</menu>", $s));' "$BASE/$f"
        continue
    fi
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
clear_caches

echo
echo "Done. Open https://<firewall>/ui/jkufw/parental  (menu: Firewall > Content Filter)"
echo "Dashboard: + Add widget > 'jk-ufw: Родительский контроль'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
