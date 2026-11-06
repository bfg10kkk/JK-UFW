#!/bin/sh
# jk-ufw: rebrand a clone of the upstream "core" repository for the jk-ufw fork.
#
#   ./rebrand-core.sh /path/to/core-clone
#
# Settings (override with environment variables):
PRODUCT=${PRODUCT:-jk-ufw}                                  # name shown in the UI, titles, login page
WWW=${WWW:-https://github.com/bfg10kkk/JK-UFW}              # project website / repository
MAINTAINER=${MAINTAINER:-jk8s@example.invalid}               # package maintainer e-mail
HOLDER=${HOLDER:-jk8s}                                       # name in the UI footer "(c) YEARS HOLDER"
HOLDER_WWW=${HOLDER_WWW:-$WWW}
YEARS=${YEARS:-2026}
PKGSITE=${PKGSITE:-}                                         # your package mirror; empty = keep upstream
CRASHURL=${CRASHURL:-}                                       # your crash report server; empty = reports stay local
#
# What it does NOT touch: LICENSE files and copyright headers in source files
# (BSD-2-Clause requires keeping them), PHP namespaces, file paths and internal
# identifiers (renaming those breaks the system).
set -e
CORE=${1:?usage: $0 /path/to/core-clone}
KIT=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$CORE/Mk/version.mk" ] || { echo "$CORE does not look like a core clone (no Mk/version.mk)"; exit 1; }

setvar() { # setvar FILE VAR VALUE  -> rewrites "VAR?=  old" keeping the ?= form
  sed -i.bak -E "s|^($2\?=[[:space:]]*).*|\1$3|" "$1" && rm -f "$1.bak"
  grep -q "^$2?=" "$1" || { echo "!! $2 not found in $1"; exit 1; }
}

echo ">>> product variables (Mk/version.mk)"
V="$CORE/Mk/version.mk"
setvar "$V" CORE_PRODUCT "$PRODUCT"
setvar "$V" CORE_WWW "$WWW"
setvar "$V" CORE_MAINTAINER "$MAINTAINER"
setvar "$V" CORE_COPYRIGHT_HOLDER "$HOLDER"
setvar "$V" CORE_COPYRIGHT_WWW "$HOLDER_WWW"
setvar "$V" CORE_COPYRIGHT_YEARS "$YEARS"
[ -n "$PKGSITE" ] && setvar "$V" CORE_PACKAGESITE "$PKGSITE"

echo ">>> console banner (motd)"
cat > "$CORE/src/opnsense/service/templates/OPNsense/Auth/motd.in" <<MOTD
------------------------------------------------
|     Hello, this is $PRODUCT %%CORE_SERIES_FW%%
|
|  Website:     $WWW
------------------------------------------------
MOTD

echo ">>> boot loader logo"
cat > "$CORE/src/root/boot/lua/brand-opnsense.lua" <<'LUA'
--
-- jk-ufw boot loader brand (the brand id stays "opnsense" so loader.conf keeps working)
--
local drawer = require("drawer")

local brand_jkufw = {
"   _ _                __          ",
"  (_) | __     _   _ / _|_      __",
"  | | |/ /____| | | | |_\\ \\ /\\ / /",
"  | |   <_____| |_| |  _|\\ V  V / ",
" _/ |_|\\_\\     \\__,_|_|   \\_/\\_/  ",
"|__/                              "
}

drawer.addBrand("opnsense", {
	graphic = brand_jkufw,
	shift = {x = 10, y = 1},
})

return true
LUA

echo ">>> page title fallback and a few UI strings"
sed -i.bak 's/headTitle|default("OPNsense")/headTitle|default("'"$PRODUCT"'")/' "$CORE/src/opnsense/mvc/app/views/layouts/default.volt"
sed -i.bak 's/keep empty to consider all local groups in OPNsense\./keep empty to consider all local groups in '"$PRODUCT"'./' "$CORE/src/www/system_authservers.php"
sed -i.bak 's/Set the deployment type of this OPNsense instance\./Set the deployment type of this '"$PRODUCT"' instance./' "$CORE/src/www/system_advanced_admin.php"
sed -i.bak 's/gettext("OPNsense Default")/gettext("'"$PRODUCT"' Default")/' "$CORE/src/www/interfaces.php"
find "$CORE/src" -name '*.bak' -delete

echo ">>> product name in system messages, certificates, 2FA, help texts and man pages"
R() { # R relative-file sed-args...  (missing files are skipped, upstream may move them)
  _f="$CORE/$1"; shift
  if [ ! -f "$_f" ]; then echo "   skip (not found): $_f"; return 0; fi
  sed -i.bak "$@" "$_f" && rm -f "$_f.bak"
}
R src/etc/inc/plugins.inc.d/webgui.inc -e 's/^server\.tag = "OPNsense"/server.tag = "'"$PRODUCT"'"/'
R src/etc/ssl/opnsense.cnf -e 's/"OPNsense Generated /"'"$PRODUCT"' Generated /'
R src/www/system_usermanager_passwordmg.php -e 's/&issuer=OPNsense/\&issuer='"$PRODUCT"'/' -e '/&image=https:\/\/docs\.opnsense\.org/d'
R src/opnsense/mvc/app/controllers/OPNsense/Auth/Api/UserController.php \
  -e 's|&issuer=OPNsense&image=https://docs\.opnsense\.org/_static/favicon\.png|\&issuer='"$PRODUCT"'|'
R src/opnsense/scripts/filter/lib/alias/uri.py -e "s/'User-Agent': 'OPNsense'/'User-Agent': '$PRODUCT'/"
R src/opnsense/scripts/firmware/update.sh -e 's/report this error log to OPNsense\./report this error log to the '"$PRODUCT"' project./'
R src/opnsense/data/firmware/upgrade.html.in -e 's/^<p>OPNsense %%CORE_SERIES%%/<p>%%CORE_PRODUCT%% %%CORE_SERIES%%/' \
  -e 's|<a href="https://forum\.opnsense\.org/" target="_blank">in the forums</a>|<a href="'"$WWW"'" target="_blank">on the project page</a>|' \
  -e 's|<a href="[^"]*" target="_blank">on the project page</a>|<a href="'"$WWW"'" target="_blank">on the project page</a>|'
R src/opnsense/mvc/app/models/OPNsense/Core/repositories/opnsense.xml \
  -e 's|<description>OPNsense (HTTPS, Amsterdam, NL)</description>|<description>Default (HTTPS, Amsterdam, NL)</description>|'
R src/www/system_authservers.php -e 's/existing in OPNsense\. /existing in '"$PRODUCT"'. /' -e 's/persisted in OPNsense\. /persisted in '"$PRODUCT"'. /'
R src/opnsense/mvc/app/controllers/OPNsense/Core/forms/hasyncSettings.xml -e 's/Newer versions of OPNsense offer/Newer versions of '"$PRODUCT"' offer/'
R src/opnsense/mvc/app/controllers/OPNsense/Firewall/forms/geoIPSettings.xml -e 's/Refer to the OPNsense documentation for/Refer to the documentation for/'
for _m in "$CORE"/src/man/man8/*.8; do
  sed -i.bak -e 's/^\.Nd OPNsense /.Nd '"$PRODUCT"' /' -e 's/first appeared in OPNsense /first appeared in version /' \
             -e 's/^until OPNsense /until version /' -e 's/^in OPNsense /in version /' \
             -e 's/directory of OPNsense packages/directory of '"$PRODUCT"' packages/' "$_m" && rm -f "$_m.bak"
done

R src/opnsense/mvc/app/models/OPNsense/Core/Hasync.xml -e 's|">OPNsense \([0-9]\)|">Version \1|'

echo ">>> crash reports go to your server or stay on the system"
CR=src/www/crash_reporter.php
NOPROD="\$is_prod = false; /* no crash report server configured (CRASHURL) */"
R $CR -e "s|CURLOPT_URL, '[^']*'|CURLOPT_URL, '$CRASHURL'|" \
  -e "s|gettext('Development deployment is configured so crash reports cannot be sent.')|gettext('An issue was detected. Copy the report below into a new issue on the project page.')|"
if [ -n "$CRASHURL" ]; then
  R $CR -e "s|^\$is_prod = false; /\* no crash report server configured (CRASHURL) \*/|\$is_prod = empty(\$config['system']['deployment']);|"
else
  R $CR -e "s|^\$is_prod = empty(\$config\['system'\]\['deployment'\]);|$NOPROD|"
fi

echo ">>> help menu points to the project page"
R src/opnsense/mvc/app/models/OPNsense/Core/Menu/Menu.xml \
  -e 's|<Documentation order="10" url="[^"]*"|<Documentation order="10" url="'"$WWW"'"|' \
  -e '/<Forum VisibleName="User Forum" .*forum\.opnsense\.org/d' \
  -e '/<Support VisibleName="Commercial Support" .*opnsense\.org/d'

echo ">>> theme names in System > Settings > General"
R src/www/system_general.php \
  -e "s|^\(                  \)<option <?= \$file == \$pconfig\['theme'\]|\1<option value=\"<?= htmlspecialchars(\$file) ?>\" <?= \$file == \$pconfig['theme']|" \
  -e "s|^\(                    \)<?=\$file;?>\$|\1<?= htmlspecialchars(['jkufw' => '$PRODUCT', 'opnsense' => '$PRODUCT classic', 'opnsense-dark' => '$PRODUCT classic dark'][\$file] ?? \$file) ?>|"

echo ">>> dashboard: jk-ufw widgets by default, no upstream news feed"
DC="$CORE/src/opnsense/mvc/app/controllers/OPNsense/Core/Api/DashboardController.php"
if [ -f "$DC" ]; then
  awk -v q="'" '
    function w(id, x, y, width) {
      printf "                [%sid%s => %s%s%s, %sx%s => %d, %sy%s => %d, %sw%s => %d],\n", q, q, q, id, q, q, q, x, q, q, y, q, q, width
    }
    /private function getDefaultDashboard/ { infn = 1 }
    infn && index($0, q "widgets" q " => [") {
      print
      w("jkufwoverview", 0, 0, 12); w("jkufwinternet", 0, 1, 4); w("jkufwsecurity", 4, 1, 8)
      w("jkufwports", 0, 2, 8); w("jkufwsystem", 8, 2, 4); w("jkufwtraffic", 0, 3, 8)
      w("jkufwclients", 8, 3, 4); w("jkufwdns", 0, 4, 8); w("jkufwvpn", 8, 4, 4)
      w("jkufwservices", 0, 5, 12)
      skip = 1; next
    }
    skip && /^[[:space:]]*\]$/ { skip = 0; infn = 0 }
    skip { next }
    { print }
  ' "$DC" > "$DC.new" && mv "$DC.new" "$DC"
fi
CX="$CORE/src/opnsense/www/js/widgets/Metadata/Core.xml"
if [ -f "$CX" ]; then
  awk '/<announcements>/ { drop = 1 } !drop { print } /<\/announcements>/ { drop = 0 }' "$CX" > "$CX.new" && mv "$CX.new" "$CX"
fi

echo ">>> defaults for new installs (config.xml.sample)"
sed -i.bak -e 's|<hostname>OPNsense</hostname>|<hostname>'"$PRODUCT"'</hostname>|' \
           -e 's|<theme>opnsense</theme>|<theme>jkufw</theme>|' "$CORE/src/etc/config.xml.sample"
rm -f "$CORE/src/etc/config.xml.sample.bak"

echo ">>> jk-ufw theme, widgets and logos"
mkdir -p "$CORE/src/opnsense/www/themes/jkufw"
rm -rf "$CORE/src/opnsense/www/themes/jkufw/build"
cp -R "$KIT/src/opnsense/www/themes/jkufw/build" "$CORE/src/opnsense/www/themes/jkufw/"
cp "$KIT"/src/opnsense/www/js/widgets/JkUfw*.js "$CORE/src/opnsense/www/js/widgets/"
cp "$KIT/src/opnsense/www/js/widgets/Metadata/JkUfw.xml" "$CORE/src/opnsense/www/js/widgets/Metadata/"
# the stock themes stay available but show the jk-ufw logo too
for t in "$CORE"/src/opnsense/www/themes/*/build/images; do
  [ "$t" = "$CORE/src/opnsense/www/themes/jkufw/build/images" ] && continue
  rm -f "$t/default-logo.png" "$t/icon-logo.png"
  cp "$KIT/assets/default-logo.svg" "$KIT/assets/icon-logo.svg" "$KIT/assets/favicon.png" "$t/"
done
echo ">>> captive portal default page"
CP="$CORE/src/opnsense/scripts/captiveportal/htdocs_default"
for f in OPNsense-logo.svg OPNsense-logo-diap.svg default-logo.svg; do cp "$KIT/assets/default-logo.svg" "$CP/images/$f"; done
cp "$KIT/assets/favicon.png" "$CP/images/favicon.png"
cp "$KIT/assets/favicon.ico" "$CP/favicon/favicon.ico"
# crimson login page; texts per zone come from jkufw.json (written by Services > Captive Portal > Guest Network)
cp "$KIT/src/opnsense/scripts/captiveportal/htdocs_default/index.html" "$CP/index.html"
cp "$KIT/src/opnsense/scripts/captiveportal/htdocs_default/css/signin.css" "$CP/css/signin.css"

cp "$KIT/LICENSE" "$CORE/src/opnsense/www/themes/jkufw/LICENSE"
cp "$KIT/LICENSE.upstream" "$CORE/src/opnsense/www/themes/jkufw/LICENSE.upstream"

echo ">>> repository documents (README, CONTRIBUTING, SECURITY, issue templates)"
for _d in README.md CONTRIBUTING.md SECURITY.md AGENTS.md; do
  sed -e "s|@PRODUCT@|$PRODUCT|g" -e "s|@WWW@|$WWW|g" "$KIT/fork/repo/$_d" > "$CORE/$_d"
done
mkdir -p "$CORE/.github/ISSUE_TEMPLATE"
rm -f "$CORE"/.github/ISSUE_TEMPLATE/*.md
for _d in "$KIT"/fork/repo/github/ISSUE_TEMPLATE/*.md "$KIT/fork/repo/github/pull_request_template.md"; do
  _t="$CORE/.github/${_d#$KIT/fork/repo/github/}"
  sed -e "s|@PRODUCT@|$PRODUCT|g" -e "s|@WWW@|$WWW|g" "$_d" > "$_t"
done

echo ">>> package file list (plist)"
( cd "$CORE/src" && find opnsense/www/themes/jkufw opnsense/www/js/widgets -type f \( -path '*/themes/jkufw/*' -o -name 'JkUfw*' \) | sed 's|^|/usr/local/|' ) > "$CORE/plist.jkufw"
cat "$CORE/plist" "$CORE/plist.jkufw" | LC_ALL=C sort -u > "$CORE/plist.new" && mv "$CORE/plist.new" "$CORE/plist" && rm -f "$CORE/plist.jkufw"

echo ">>> done. Product variables now:"
grep -E '^CORE_(PRODUCT|WWW|MAINTAINER|COPYRIGHT_HOLDER|COPYRIGHT_WWW|COPYRIGHT_YEARS|PACKAGESITE)\?=' "$V"
echo "Review with: git -C $CORE status && git -C $CORE diff --stat"
