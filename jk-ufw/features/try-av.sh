#!/bin/sh
# jk-ufw: put the "Antivirus & Sandbox" page (stream antivirus through the web proxy, files cut out of
# traffic by Suricata, hash reputation, sandbox) onto a running firewall, without rebuilding the image.
# Run as root (console option 8 "Shell", or SSH):
#
#   fetch -o /tmp/try-av.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-av.sh
#   sh /tmp/try-av.sh                    # files from stable/26.7
#   sh /tmp/try-av.sh <branch-or-commit> # or from another branch / an exact commit
#
# The plugins os-clamav, os-c-icap and os-squid are installed from the page itself when web scanning is
# switched on (System > Firmware does the same).
#
# Undo: switch both protections off on the page and press "Apply" first (that removes the port forwards
#       and the Suricata rules), then: sh /tmp/try-av.sh --remove
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
TEMPLATE="$BASE/service/templates/OPNsense/IDS/suricata.yaml"
INSTALLRULES="$BASE/scripts/suricata/installRules.py"
INC=/usr/local/etc/inc/plugins.inc.d/jkufw_av.inc
OWN="
mvc/app/controllers/OPNsense/JkUfw/AntivirusController.php
mvc/app/controllers/OPNsense/JkUfw/Api/AntivirusController.php
mvc/app/models/OPNsense/JkUfw/Antivirus.php
mvc/app/models/OPNsense/JkUfw/Antivirus.xml
mvc/app/views/OPNsense/JkUfw/antivirus.volt
scripts/jkufw/av.py
service/conf/actions.d/actions_jkufw_av.conf
"

clear_caches() {
    # menu and ACL are cached; the next page load rebuilds them. configd picks up new actions on restart.
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
    service configd restart >/dev/null
    configctl cron restart >/dev/null || true
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
            $q = $kind == "menu" ? "/menu/Firewall/Antivirus" : "/acl/page-jkufw-antivirus";
            foreach ($xp->query($q) as $old) { $old->parentNode->removeChild($old); }
            if ($mode == "add") {
                if ($kind == "menu") {
                    $fw = $xp->query("/menu/Firewall")->item(0);
                    if ($fw === null) { $fw = $root->appendChild($dom->createElement("Firewall")); }
                    $e = $fw->appendChild($dom->createElement("Antivirus"));
                    foreach (["VisibleName" => "Antivirus & Sandbox", "order" => "46", "url" => "/ui/jkufw/antivirus", "cssClass" => "fa fa-shield fa-fw"] as $k => $v) {
                        $e->setAttribute($k, $v);
                    }
                } else {
                    $p = $root->appendChild($dom->createElement("page-jkufw-antivirus"));
                    $p->appendChild($dom->createElement("name", "Firewall: Antivirus and Sandbox"));
                    $ps = $p->appendChild($dom->createElement("patterns"));
                    foreach (["ui/jkufw/antivirus", "api/jkufw/antivirus/*", "api/core/firmware/install/*",
                              "api/core/firmware/upgradestatus", "api/clamav/service/*", "api/cicap/service/*",
                              "api/proxy/service/*"] as $pat) {
                        $ps->appendChild($dom->createElement("pattern", $pat));
                    }
                }
            }
            $dom->save($file);
        }
    ' "$1" "$MENU" "$ACL"
}

# Suricata template: file-store output when the feature is on; rule installer: leave jkufw-*.rules alone.
# Both are edited in place (backup *.jkufw-orig), so the rest of the box's own version stays untouched.
patch_core() {
    /usr/local/bin/python3 - "$1" "$TEMPLATE" "$INSTALLRULES" <<'PY'
import os, shutil, sys
mode, template, installer = sys.argv[1:4]
MARK = "{# jk-ufw antivirus"
BLOCK = """{# jk-ufw antivirus: files matched by jkufw-av.rules are written here and analysed by scripts/jkufw/av.py #}
{% if not helpers.empty('OPNsense.JkUfw.antivirus.files.enabled') %}
  - file-store:
      version: 2
      enabled: yes
      dir: /var/log/suricata/filestore
      write-fileinfo: yes
      force-hash: [sha256, md5]
      stream-depth: 0
      max-open-files: 1000
{% endif %}

"""
ANCHOR = "  - stats:\n"
OLD = "and rule_info_record['metadata']['sid'] in rule_updates:"
NEW = "and rule_info_record['metadata']['sid'] in rule_updates \\\n                    and not os.path.basename(filename).startswith('jkufw-'):"
for path, add, remove in ((template, lambda s: s.replace(ANCHOR, BLOCK + ANCHOR, 1) if MARK not in s and ANCHOR in s else s,
                           lambda s: s.replace(BLOCK, "")),
                          (installer, lambda s: s.replace(OLD, NEW, 1) if "jkufw-" not in s else s,
                           lambda s: s.replace(NEW, OLD))):
    if not os.path.exists(path):
        print("!!! missing " + path)
        continue
    s = open(path).read()
    t = add(s) if mode == "add" else remove(s)
    if t != s:
        if mode == "add" and not os.path.exists(path + ".jkufw-orig"):
            shutil.copy2(path, path + ".jkufw-orig")
        open(path, "w").write(t)
    if mode == "add" and (("jkufw" not in t)):
        print("!!! could not patch " + path + " (different version?)")
PY
}

if [ "$REF" = "--remove" ]; then
    for f in $OWN; do
        rm -f "$BASE/$f"
    done
    rm -f "$INC" /usr/local/etc/suricata/rules/jkufw-av.rules /var/db/clamav/jkufw-blocked.hsb
    patch_core remove
    edit_menu_acl remove
    clear_caches
    echo "Removed. Quarantine and history stay in /var/db/jkufw/av (delete it by hand if not needed)."
    echo "If the page was still on: delete port forwards 'jk-ufw AV: ...' (Firewall > NAT > Port Forward)"
    echo "and switch off ICAP in Services > Squid Web Proxy."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-av.XXXXXX)
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
echo ">>> jk-ufw antivirus from $REF ($SHA)"

for f in $OWN; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/opnsense/$f" \
        || { echo "!!! cannot download $f"; exit 1; }
done
fetch -q -o "$TMP/jkufw_av.inc" "https://raw.githubusercontent.com/$OWNER_REPO/$SHA/src/etc/inc/plugins.inc.d/jkufw_av.inc" \
    || { echo "!!! cannot download jkufw_av.inc"; exit 1; }
php -l "$TMP/mvc/app/controllers/OPNsense/JkUfw/Api/AntivirusController.php" >/dev/null \
    || { echo "!!! downloaded controller is broken, nothing installed"; exit 1; }
/usr/local/bin/python3 -m py_compile "$TMP/scripts/jkufw/av.py" \
    || { echo "!!! downloaded av.py is broken, nothing installed"; exit 1; }

for f in $OWN; do
    mkdir -p "$BASE/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "$BASE/$f"
done
chmod 0755 "$BASE/scripts/jkufw/av.py"
install -m 0644 "$TMP/jkufw_av.inc" "$INC"
patch_core add
edit_menu_acl add
clear_caches

echo
echo "Done. Open https://<firewall>/ui/jkufw/antivirus  (menu: Firewall > Antivirus & Sandbox)"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
