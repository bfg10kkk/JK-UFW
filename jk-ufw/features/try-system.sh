#!/bin/sh
# jk-ufw: give every page of the "System" menu the look of the jk-ufw feature pages
# (hero header, section switcher, cards, segmented tabs, sticky apply bar) on a running firewall,
# without rebuilding the image. Run as root on the firewall (console option 8 "Shell", or over SSH):
#
#   fetch -o /tmp/try-system.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-system.sh
#   sh /tmp/try-system.sh                 # files from stable/26.7
#   sh /tmp/try-system.sh <branch>        # or from another branch, e.g. one under review
#
# Undo: sh /tmp/try-system.sh --remove   (restores the three page frames saved as *.jkufw-orig)
#
# Only presentation changes: two new files (css/jkufw-system.css, js/jkufw-system.js) plus a few lines
# that load them in the page frames (MVC layout default.volt, legacy head.inc and fbegin.inc), added in place.
#
# BSD-2-Clause, see jk-ufw/LICENSE.
set -e

REPO="https://raw.githubusercontent.com/bfg10kkk/JK-UFW"
BRANCH="${1:-stable/26.7}"
VOLT=/usr/local/opnsense/mvc/app/views/layouts/default.volt
HEAD=/usr/local/www/head.inc
FBEGIN=/usr/local/www/fbegin.inc

clear_caches() {
    # compiled volt templates are cached; the next page load compiles them again
    rm -f /usr/local/opnsense/mvc/app/cache/*.php
}

# add_after <file> <line anchor> <marker> <text>: insert text after the first line containing the anchor,
# unless the file already contains the marker (so running the script twice changes nothing)
add_after() {
    grep -qF "$3" "$1" && return 0
    grep -qF "$2" "$1" || { echo "!!! $1: anchor '$2' not found, skipped"; return 0; }
    [ -f "$1.jkufw-orig" ] || cp -p "$1" "$1.jkufw-orig"
    # text goes through a file: FreeBSD awk refuses newlines in -v values
    printf '%s\n' "$4" > "$1.jkufw-txt"
    awk -v pat="$2" -v txt="$1.jkufw-txt" \
        '{ print } !done && index($0, pat) { while ((getline l < txt) > 0) print l; done = 1 }' "$1" > "$1.jkufw-tmp"
    rm -f "$1.jkufw-txt"
    cat "$1.jkufw-tmp" > "$1" && rm -f "$1.jkufw-tmp"
}

if [ "$BRANCH" = "--remove" ]; then
    for f in $VOLT $HEAD $FBEGIN; do
        [ -f "$f.jkufw-orig" ] && mv -f "$f.jkufw-orig" "$f"
    done
    rm -f /usr/local/opnsense/www/css/jkufw-system.css /usr/local/opnsense/www/js/jkufw-system.js
    clear_caches
    echo "Removed. System pages are back to the plain theme."
    exit 0
fi

TMP=$(mktemp -d /tmp/jkufw-system.XXXXXX)
trap 'rm -rf "$TMP"' EXIT
for f in css/jkufw-system.css js/jkufw-system.js; do
    fetch -q -o "$TMP/$(basename $f)" "$REPO/$BRANCH/src/opnsense/www/$f" \
        || { echo "!!! cannot download $f from branch $BRANCH"; exit 1; }
done
install -m 0644 "$TMP/jkufw-system.css" /usr/local/opnsense/www/css/jkufw-system.css
install -m 0644 "$TMP/jkufw-system.js" /usr/local/opnsense/www/js/jkufw-system.js

# load the two files and mark System pages; the stock frames are patched in place (backups: *.jkufw-orig)
add_after $VOLT "/js/theme.js', theme_name)" jkufw-system.js \
'    <link href="/ui/css/jkufw-system.css" rel="stylesheet">
    <script src="/ui/js/jkufw-system.js"></script>'
add_after $VOLT 'layout_partials/base_menu_system' jkufwSystemMark \
'      <script>window.jkufwSystemMark && jkufwSystemMark();</script>'
add_after $HEAD '/ui/js/opnsense_status.js' jkufw-system.js \
'    <link rel="stylesheet" type="text/css" href="/ui/css/jkufw-system.css">
    <script src="/ui/js/jkufw-system.js"></script>'
add_after $FBEGIN '/ui/js/opnsense_favorites.js' jkufwSystemMark \
'<script>window.jkufwSystemMark && jkufwSystemMark();</script>'
clear_caches

echo
echo "Done. Open any page under System, e.g. https://<firewall>/ui/auth/user"
echo "Note: a core update (System > Firmware) overwrites the patched files; run this script again after it."
