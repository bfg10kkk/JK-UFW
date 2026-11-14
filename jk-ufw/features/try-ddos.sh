#!/bin/sh
# jk-ufw: put the "Attack Protection" page (DDoS limits and block list, threat intelligence feeds,
# log export to a SIEM) and its dashboard widget onto a running firewall, without rebuilding the image.
# Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-ddos.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-ddos.sh
#   sh /tmp/try-ddos.sh                    # files from stable/26.7
#   sh /tmp/try-ddos.sh <branch-or-commit> # or from another branch / an exact commit
#
# Undo: on the page turn protection off, remove the threat feeds and SIEM targets and press "Apply" first
#       (that puts every changed rule and setting back), then: sh /tmp/try-ddos.sh --remove
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
mvc/app/controllers/OPNsense/JkUfw/DdosController.php
mvc/app/controllers/OPNsense/JkUfw/Api/DdosController.php
mvc/app/models/OPNsense/JkUfw/Ddos.php
mvc/app/models/OPNsense/JkUfw/Ddos.xml
mvc/app/views/OPNsense/JkUfw/ddos.volt
www/js/widgets/JkUfwDdos.js
scripts/jkufw/ddos.py
service/conf/actions.d/actions_jkufw_ddos.conf
service/templates/OPNsense/JkUfw/Siem/+TARGETS
service/templates/OPNsense/JkUfw/Siem/jkufw-siem.conf
service/templates/OPNsense/Syslog/local/jkufw_ddos.conf
"
# outside /usr/local/opnsense: cron job and log file hooks
PLUGIN=/usr/local/etc/inc/plugins.inc.d/jkufw_ddos.inc
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
            $q = $kind == "menu" ? "/menu/Firewall/AttackProtection" : "/acl/page-jkufw-ddos";
            foreach ($xp->query($q) as $old) { $old->parentNode->removeChild($old); }
            if ($mode == "add") {
                if ($kind == "menu") {
                    $fw = $xp->query("/menu/Firewall")->item(0);
                    if ($fw === null) { $fw = $root->appendChild($dom->createElement("Firewall")); }
                    $e = $fw->appendChild($dom->createElement("AttackProtection"));
                    foreach (["VisibleName" => "Attack Protection", "order" => "4", "url" => "/ui/jkufw/ddos", "cssClass" => "fa fa-shield fa-fw"] as $k => $v) {
                        $e->setAttribute($k, $v);
                    }
                } else {
                    $p = $root->appendChild($dom->createElement("page-jkufw-ddos"));
                    $p->appendChild($dom->createElement("name", "Firewall: Attack Protection"));
                    $ps = $p->appendChild($dom->createElement("patterns"));
                    $ps->appendChild($dom->createElement("pattern", "ui/jkufw/ddos"));
                    $ps->appendChild($dom->createElement("pattern", "api/jkufw/ddos/*"));
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
    rm -f "$PLUGIN" /usr/local/etc/syslog-ng.conf.d/jkufw-siem.conf
    edit_menu_acl remove
    clear_caches
    service configd restart >/dev/null 2>&1 || true
    configctl cron restart >/dev/null 2>&1 || true
    configctl syslog restart >/dev/null 2>&1 || true
    echo "Removed. If protection was still on, delete rules marked [jk-ufw ddos] / [jk-ufw ioc] (Firewall > Rules),"
    echo "aliases jkufw_ddos_* / jkufw_ioc_* and the tunable net.inet.icmp.icmplim if you do not want them."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-ddos.XXXXXX)
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
echo ">>> jk-ufw attack protection from $REF ($SHA)"

for f in $OWN $SHARED; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/opnsense/$f" \
        || { echo "!!! cannot download $f"; exit 1; }
done
fetch -q -o "$TMP/plugin.inc" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/etc/inc/plugins.inc.d/jkufw_ddos.inc" \
    || { echo "!!! cannot download jkufw_ddos.inc"; exit 1; }
for f in "$TMP/mvc/app/controllers/OPNsense/JkUfw/Api/DdosController.php" "$TMP/plugin.inc"; do
    php -l "$f" >/dev/null || { echo "!!! downloaded file $f is broken, nothing installed"; exit 1; }
done

for f in $OWN $SHARED; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
chmod 0755 "$BASE/scripts/jkufw/ddos.py"
install -m 0644 "$TMP/plugin.inc" "$PLUGIN"
edit_menu_acl add
clear_caches
# new configd actions and the log file filter need a configd restart and a syslog template reload
service configd restart >/dev/null
configctl template reload OPNsense/Syslog >/dev/null
configctl syslog restart >/dev/null || true

echo
echo "Done. Open https://<firewall>/ui/jkufw/ddos  (menu: Firewall > Attack Protection)"
echo "Dashboard: + Add widget > 'jk-ufw: защита от атак'."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
