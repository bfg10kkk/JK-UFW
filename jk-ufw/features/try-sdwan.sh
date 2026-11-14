#!/bin/sh
# jk-ufw: put the "SD-WAN" page (several internet links: health checks, failover, load balancing,
# traffic routes) and its dashboard widget onto a running firewall, without rebuilding the image.
# Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-sdwan.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-sdwan.sh
#   sh /tmp/try-sdwan.sh                    # files from stable/26.7
#   sh /tmp/try-sdwan.sh <branch-or-commit> # or from another branch / an exact commit
#
# Undo: turn SD-WAN off on the page and press "Apply" first (that removes its rules and gateway groups),
#       then: sh /tmp/try-sdwan.sh --remove
#
# Files are downloaded by commit hash: raw.githubusercontent.com caches branch URLs for minutes,
# a hash always gives the exact version.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REF="${1:-stable/26.7}"
OWNER_REPO="bfg10kkk/JK-UFW"
BASE=/usr/local/opnsense
MENU="$BASE/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml"
ACL="$BASE/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml"
OWN="
mvc/app/controllers/OPNsense/JkUfw/SdwanController.php
mvc/app/controllers/OPNsense/JkUfw/Api/SdwanController.php
mvc/app/models/OPNsense/JkUfw/Sdwan.php
mvc/app/models/OPNsense/JkUfw/Sdwan.xml
mvc/app/views/OPNsense/JkUfw/sdwan.volt
www/js/widgets/JkUfwSdwan.js
"
SHARED="
www/js/widgets/JkUfwCommon.js
www/js/widgets/Metadata/JkUfw.xml
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

# add (or with "remove" take out) our menu entry and ACL page, keeping what other features put there
edit_menu_acl() {
    php -r '
        $mode = $argv[1];
        $files = ["menu" => $argv[2], "acl" => $argv[3]];
        foreach ($files as $kind => $file) {
            $dom = new DOMDocument();
            $dom->preserveWhiteSpace = false;
            $dom->formatOutput = true;
            if (is_file($file)) {
                $dom->load($file);
            } else {
                if ($mode == "remove") { continue; }
                @mkdir(dirname($file), 0755, true);
                $dom->loadXML($kind == "menu" ? "<menu/>" : "<acl/>");
            }
            $root = $dom->documentElement;
            $xp = new DOMXPath($dom);
            $q = $kind == "menu" ? "/menu/Lobby/SDWAN" : "/acl/page-jkufw-sdwan";
            foreach ($xp->query($q) as $old) { $old->parentNode->removeChild($old); }
            if ($mode == "add") {
                if ($kind == "menu") {
                    $lobby = $xp->query("/menu/Lobby")->item(0);
                    if ($lobby === null) { $lobby = $root->appendChild($dom->createElement("Lobby")); }
                    $e = $lobby->appendChild($dom->createElement("SDWAN"));
                    foreach (["VisibleName" => "SD-WAN", "order" => "3", "url" => "/ui/jkufw/sdwan", "cssClass" => "fa fa-random fa-fw"] as $k => $v) {
                        $e->setAttribute($k, $v);
                    }
                } else {
                    $p = $root->appendChild($dom->createElement("page-jkufw-sdwan"));
                    $p->appendChild($dom->createElement("name", "Lobby: SD-WAN"));
                    $ps = $p->appendChild($dom->createElement("patterns"));
                    $ps->appendChild($dom->createElement("pattern", "ui/jkufw/sdwan"));
                    $ps->appendChild($dom->createElement("pattern", "api/jkufw/sdwan/*"));
                }
            }
            $dom->save($file);
        }
    ' "$1" "$MENU" "$ACL"
}

if [ "$REF" = "--remove" ]; then
    for f in $OWN; do
        rm -f "$BASE/$f"
    done
    edit_menu_acl remove
    clear_caches
    echo "Removed. If SD-WAN was still on, delete rules marked [jk-ufw sdwan] (Firewall > Rules > Floating)"
    echo "and gateway groups JKUFW_SDWAN* (System > Gateways > Group)."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-sdwan.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# branch (or tag) -> commit hash
case "$REF" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) SHA="$REF" ;;
    *)
        fetch -q -o "$TMP/commit.json" "https://api.github.com/repos/$OWNER_REPO/commits/$REF" \
            || { echo "!!! cannot look up branch $REF on GitHub"; exit 1; }
        SHA=$(php -r '$j = json_decode(file_get_contents($argv[1]), true); echo $j["sha"] ?? "";' "$TMP/commit.json")
        [ -n "$SHA" ] || { echo "!!! branch $REF not found"; exit 1; }
        ;;
esac
echo ">>> jk-ufw SD-WAN from $REF ($SHA)"

for f in $OWN $SHARED; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/opnsense/$f" \
        || { echo "!!! cannot download $f"; exit 1; }
done
php -l "$TMP/mvc/app/controllers/OPNsense/JkUfw/Api/SdwanController.php" >/dev/null \
    || { echo "!!! downloaded controller is broken, nothing installed"; exit 1; }

for f in $OWN $SHARED; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
edit_menu_acl add
clear_caches

echo
echo "Done. Open https://<firewall>/ui/jkufw/sdwan  (menu: Lobby > SD-WAN)"
echo "Dashboard: + Add widget > 'jk-ufw: SD-WAN'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
