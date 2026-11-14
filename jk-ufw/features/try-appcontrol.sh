#!/bin/sh
# jk-ufw: put the "Application Control" page (recognise and block ~60 applications, usage per device) and the
# extended "Content Filter" page (HTTPS check by site name, DNS over HTTPS / QUIC blocking) onto a running
# firewall, without rebuilding the image. Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-appcontrol.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-appcontrol.sh
#   sh /tmp/try-appcontrol.sh                    # files from stable/26.7
#   sh /tmp/try-appcontrol.sh <branch-or-commit> # or from another branch / an exact commit
#
# Undo: switch application control, the HTTPS check, DoH and QUIC blocking off and press "Apply" first
#       (that removes the firewall rules), then: sh /tmp/try-appcontrol.sh --remove
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
opnsense/mvc/app/controllers/OPNsense/JkUfw/AppcontrolController.php
opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/AppcontrolController.php
opnsense/mvc/app/models/OPNsense/JkUfw/AppControl.php
opnsense/mvc/app/models/OPNsense/JkUfw/AppControl.xml
opnsense/mvc/app/views/OPNsense/JkUfw/appcontrol.volt
opnsense/scripts/jkufw/appcatalog.json
opnsense/scripts/jkufw/appcontrol.py
"
# the Content Filter page gets the new switches; the Telegram feature shares the configd and cron files
SHARED="
opnsense/mvc/app/controllers/OPNsense/JkUfw/ParentalController.php
opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/ParentalController.php
opnsense/mvc/app/models/OPNsense/JkUfw/Parental.php
opnsense/mvc/app/models/OPNsense/JkUfw/Parental.xml
opnsense/mvc/app/views/OPNsense/JkUfw/parental.volt
opnsense/service/conf/actions.d/actions_jkufw.conf
etc/inc/plugins.inc.d/jkufw.inc
"
GENERATED="
/usr/local/etc/suricata/rules/jkufw-appcontrol.rules
/usr/local/etc/suricata/conf.d/jkufw-appcontrol.yaml
/usr/local/etc/unbound.opnsense.d/jkufw-appcontrol.conf
/var/unbound/etc/jkufw-appcontrol.conf
"

# src/<path> is installed as /usr/local/<path>
target() {
    echo "/usr/local/$1"
}

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
}

# add (or with "remove" take out) our menu entries and ACL pages, keeping what other features put there
edit_menu_acl() {
    php -r '
        $mode = $argv[1];
        $files = ["menu" => $argv[2], "acl" => $argv[3]];
        $menu = [
            "AppControl" => ["VisibleName" => "Application Control", "order" => "46", "url" => "/ui/jkufw/appcontrol", "cssClass" => "fa fa-th-large fa-fw"],
            "ContentFilter" => ["VisibleName" => "Content Filter", "order" => "45", "url" => "/ui/jkufw/parental", "cssClass" => "fa fa-child fa-fw"],
        ];
        $acl = [
            "page-jkufw-appcontrol" => ["Firewall: Application Control", ["ui/jkufw/appcontrol", "api/jkufw/appcontrol/*"]],
            "page-jkufw-parental" => ["Firewall: Content Filter and Parental Control", ["ui/jkufw/parental", "api/jkufw/parental/*"]],
        ];
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
            if ($kind == "menu") {
                $fw = $xp->query("/menu/Firewall")->item(0);
                if ($fw === null) { $fw = $root->appendChild($dom->createElement("Firewall")); }
                foreach ($menu as $tag => $attrs) {
                    $old = $xp->query("/menu/Firewall/" . $tag)->item(0);
                    /* removal only takes our own entry: the content filter stays with its own feature */
                    if ($mode == "remove" && $tag == "AppControl" && $old !== null) { $fw->removeChild($old); }
                    if ($mode == "add" && $old === null) {
                        $e = $fw->appendChild($dom->createElement($tag));
                        foreach ($attrs as $k => $v) { $e->setAttribute($k, $v); }
                    }
                }
            } else {
                foreach ($acl as $tag => [$name, $patterns]) {
                    $old = $xp->query("/acl/" . $tag)->item(0);
                    if ($mode == "remove" && $tag == "page-jkufw-appcontrol" && $old !== null) { $root->removeChild($old); }
                    if ($mode == "add" && $old === null) {
                        $p = $root->appendChild($dom->createElement($tag));
                        $p->appendChild($dom->createElement("name", $name));
                        $ps = $p->appendChild($dom->createElement("patterns"));
                        foreach ($patterns as $pat) { $ps->appendChild($dom->createElement("pattern", $pat)); }
                    }
                }
            }
            $dom->save($file);
        }
    ' "$1" "$MENU" "$ACL"
}

if [ "$REF" = "--remove" ]; then
    for f in $OWN; do
        rm -f "$(target "$f")"
    done
    had_unbound=0
    [ -f /usr/local/etc/unbound.opnsense.d/jkufw-appcontrol.conf ] && had_unbound=1
    for f in $GENERATED; do
        rm -f "$f"
    done
    rm -rf /usr/local/etc/suricata/jkufw /var/db/jkufw/lists /var/run/jkufw-appcontrol.json
    edit_menu_acl remove
    clear_caches
    /usr/local/sbin/configctl template reload OPNsense/IDS >/dev/null
    /usr/local/opnsense/scripts/suricata/installRules.py >/dev/null 2>&1 || true
    if /usr/local/etc/rc.d/suricata status >/dev/null 2>&1; then
        /usr/local/etc/rc.d/suricata restart >/dev/null 2>&1 || true
    fi
    [ "$had_unbound" = 1 ] && /usr/local/sbin/configctl unbound restart >/dev/null
    service configd restart >/dev/null 2>&1 || true
    echo "Removed. If you did not switch everything off first, delete rules marked [jk-ufw app]"
    echo "(Firewall > Rules > Floating) and aliases jkufw_appctl_* (Firewall > Aliases)."
    echo "The Content Filter page stays (it belongs to try-parental.sh)."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-appcontrol.XXXXXX)
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
echo ">>> jk-ufw application control from $REF ($SHA)"

for f in $OWN $SHARED; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/$f" \
        || { echo "!!! cannot download $f"; exit 1; }
done
for f in opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/AppcontrolController.php \
         opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/ParentalController.php etc/inc/plugins.inc.d/jkufw.inc; do
    php -l "$TMP/$f" >/dev/null || { echo "!!! downloaded $f is broken, nothing installed"; exit 1; }
done
/usr/local/bin/python3 -m py_compile "$TMP/opnsense/scripts/jkufw/appcontrol.py" \
    || { echo "!!! downloaded appcontrol.py is broken, nothing installed"; exit 1; }

for f in $OWN $SHARED; do
    dst=$(target "$f")
    mkdir -p "$(dirname "$dst")"
    install -m 0644 "$TMP/$f" "$dst"
done
chmod 0755 "$BASE/scripts/jkufw/appcontrol.py"
edit_menu_acl add
clear_caches
# new configd actions (jkufw appcontrol.*) and the daily list refresh in cron
service configd restart >/dev/null
/usr/local/sbin/configctl cron restart >/dev/null 2>&1 || true

echo
echo "Done. Open https://<firewall>/ui/jkufw/appcontrol  (menu: Firewall > Application Control)"
echo "HTTPS check, DNS over HTTPS and QUIC blocking: Firewall > Content Filter, card 'Для всей сети'."
echo "Application control needs the IPS (Services > Intrusion Detection); the page can switch it on for LAN."
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
