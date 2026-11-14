#!/bin/sh
# jk-ufw: put the "Web Protection (WAF)" page onto a running firewall, without rebuilding the image.
# Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-waf.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-waf.sh
#   sh /tmp/try-waf.sh                    # files from stable/26.7
#   sh /tmp/try-waf.sh <branch-or-commit> # or from another branch / an exact commit
#
# The add-on packages it needs (os-nginx) are installed from the page itself.
#
# Undo: turn the feature off on the page and press "Apply" first (that removes its settings and rules),
#       then: sh /tmp/try-waf.sh --remove
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
mvc/app/controllers/OPNsense/JkUfw/WafController.php
mvc/app/controllers/OPNsense/JkUfw/Api/WafController.php
mvc/app/models/OPNsense/JkUfw/Waf.php
mvc/app/models/OPNsense/JkUfw/Waf.xml
mvc/app/views/OPNsense/JkUfw/waf.volt
"
# shared with the other "published service" page (WAF / mail protection); left in place on --remove
SHARED="
mvc/app/models/OPNsense/JkUfw/Publish.php
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
        $section = "Firewall"; $item = "WAF";
        $attrs = ["VisibleName" => "Web Protection (WAF)", "order" => "46", "url" => "/ui/jkufw/waf", "cssClass" => "fa fa-shield fa-fw"];
        $page = "page-jkufw-waf"; $pname = "Firewall: Web Protection (WAF)";
        $patterns = explode(" ", "ui/jkufw/waf api/jkufw/waf/* api/nginx/service/reconfigure api/core/firmware/install/os-nginx api/core/firmware/upgradestatus");
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
            $q = $kind == "menu" ? "/menu/$section/$item" : "/acl/$page";
            foreach ($xp->query($q) as $old) { $old->parentNode->removeChild($old); }
            if ($mode == "add") {
                if ($kind == "menu") {
                    $sec = $xp->query("/menu/$section")->item(0);
                    if ($sec === null) { $sec = $root->appendChild($dom->createElement($section)); }
                    $e = $sec->appendChild($dom->createElement($item));
                    foreach ($attrs as $k => $v) { $e->setAttribute($k, $v); }
                } else {
                    $p = $root->appendChild($dom->createElement($page));
                    $p->appendChild($dom->createElement("name", $pname));
                    $ps = $p->appendChild($dom->createElement("patterns"));
                    foreach ($patterns as $pat) { $ps->appendChild($dom->createElement("pattern", $pat)); }
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
    echo "Removed. If the WAF was still on, its objects are marked 'jk-ufw waf:' in Services > Nginx and its rules '[jk-ufw waf]' in Firewall > Rules."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-waf.XXXXXX)
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
echo ">>> jk-ufw Web Protection (WAF) from $REF ($SHA)"

for f in $OWN $SHARED; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/opnsense/$f" \
        || { echo "!!! cannot download $f"; exit 1; }
done
for f in $OWN $SHARED; do
    case "$f" in
        *.php) php -l "$TMP/$f" >/dev/null || { echo "!!! downloaded $f is broken, nothing installed"; exit 1; } ;;
    esac
done

for f in $OWN $SHARED; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
edit_menu_acl add
clear_caches

echo
echo "Done. Open https://<firewall>/ui/jkufw/waf  (menu: Firewall > Web Protection (WAF))"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
