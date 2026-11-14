#!/bin/sh
# jk-ufw: put the "Mail Protection" page onto a running firewall, without rebuilding the image.
# Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-mail.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-mail.sh
#   sh /tmp/try-mail.sh                    # files from stable/26.7
#   sh /tmp/try-mail.sh <branch-or-commit> # or from another branch / an exact commit
#
# The add-on packages it needs (os-postfix, os-rspamd, os-clamav, os-redis) are installed from the page itself.
#
# Undo: turn the feature off on the page and press "Apply" first (that removes its settings and rules),
#       then: sh /tmp/try-mail.sh --remove
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
mvc/app/controllers/OPNsense/JkUfw/MailController.php
mvc/app/controllers/OPNsense/JkUfw/Api/MailController.php
mvc/app/models/OPNsense/JkUfw/Mail.php
mvc/app/models/OPNsense/JkUfw/Mail.xml
mvc/app/views/OPNsense/JkUfw/mail.volt
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
        $section = "Services"; $item = "MailProtection";
        $attrs = ["VisibleName" => "Mail Protection", "order" => "5", "url" => "/ui/jkufw/mail", "cssClass" => "fa fa-envelope fa-fw"];
        $page = "page-jkufw-mail"; $pname = "Services: Mail Protection";
        $patterns = explode(" ", "ui/jkufw/mail api/jkufw/mail/* api/postfix/service/reconfigure api/rspamd/service/reconfigure api/clamav/service/reconfigure api/clamav/service/freshclam api/redis/service/reconfigure api/core/firmware/install/os-postfix api/core/firmware/install/os-rspamd api/core/firmware/install/os-clamav api/core/firmware/install/os-redis api/core/firmware/upgradestatus");
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
    echo "Removed. If mail protection was still on, turn Postfix off in Services > Postfix and delete the rules '[jk-ufw mail]' in Firewall > Rules."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-mail.XXXXXX)
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
echo ">>> jk-ufw Mail Protection from $REF ($SHA)"

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
echo "Done. Open https://<firewall>/ui/jkufw/mail  (menu: Services > Mail Protection)"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
