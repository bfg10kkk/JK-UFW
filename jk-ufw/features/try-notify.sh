#!/bin/sh
# jk-ufw: put the Telegram notifications page and watcher onto a running firewall for testing,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-notify.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-notify.sh
#   sh /tmp/try-notify.sh                                # files from stable/26.7
#   sh /tmp/try-notify.sh claude/project-thread-mwgpm4   # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-notify.sh --remove   (or reinstall core: opnsense-revert core)
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
FILES="
etc/inc/plugins.inc.d/jkufw.inc
opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/NotifyController.php
opnsense/mvc/app/controllers/OPNsense/JkUfw/NotifyController.php
opnsense/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml
opnsense/mvc/app/models/OPNsense/JkUfw/Notify.php
opnsense/mvc/app/models/OPNsense/JkUfw/Notify.xml
opnsense/mvc/app/views/OPNsense/JkUfw/notify.volt
opnsense/scripts/jkufw/notify.py
opnsense/service/conf/actions.d/actions_jkufw.conf
"
MENU=opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml

reload() {
    # menu and ACL are cached; the next page load rebuilds them. configd picks up the new actions on restart.
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml /var/lib/php/tmp/opnsense_acl_cache.json
    service configd restart >/dev/null
    configctl cron restart >/dev/null
}

if [ "$BRANCH" = "--remove" ]; then
    for f in $FILES; do rm -f "/usr/local/$f"; done
    rm -rf /usr/local/opnsense/scripts/jkufw /var/db/jkufw
    if [ -f "/usr/local/$MENU" ] && grep -q '/ui/jkufw/notify' "/usr/local/$MENU" && ! grep -q '/ui/ids/threats' "/usr/local/$MENU"; then
        rm -f "/usr/local/$MENU"
    fi
    reload
    echo "Removed. Settings stay in config.xml (OPNsense/JkUfw/notify) and are ignored."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-notify.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in $FILES $MENU; do
    mkdir -p "$TMP/$(dirname "$f")"
    fetch -q -o "$TMP/$f" "$REPO/$BRANCH/src/$f" || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
# keep menu entries of other jk-ufw features (e.g. Threat Management) if the branch's Menu.xml lacks them
if [ -f "/usr/local/$MENU" ] && grep -q '/ui/ids/threats' "/usr/local/$MENU" && ! grep -q '/ui/ids/threats' "$TMP/$MENU"; then
    grep -q '/ui/jkufw/notify' "/usr/local/$MENU" || sed -i '' 's|</menu>|    <System><Settings><Notifications VisibleName="Notifications" url="/ui/jkufw/notify"/></Settings></System>\
</menu>|' "/usr/local/$MENU"
    rm -f "$TMP/$MENU"
fi
for f in $FILES $MENU; do
    [ -f "$TMP/$f" ] || continue
    mkdir -p "/usr/local/$(dirname "$f")"
    install -m 0644 "$TMP/$f" "/usr/local/$f"
done
chmod 0755 /usr/local/opnsense/scripts/jkufw/notify.py
reload

echo
echo "Done. Open https://<firewall>/ui/jkufw/notify"
echo "(menu: System > Settings > Notifications)"
echo "Note: a core update (System > Firmware) overwrites these files; run this script again after it."
