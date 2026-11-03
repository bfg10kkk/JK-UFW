#!/bin/sh
# jk-ufw: установка темы и виджетов дашборда на работающий файрвол (запускать на нём от root).
#   sh install.sh            — установить / обновить
#   sh install.sh uninstall  — удалить
set -e
WWW=/usr/local/opnsense/www
DST=$WWW/themes/jkufw
WDIR=$WWW/js/widgets
HERE=$(cd "$(dirname "$0")" && pwd)
if [ "$1" = "uninstall" ]; then
  rm -rf "$DST" "$WWW/themes/crimson"
  rm -f "$WDIR"/JkUfw*.js "$WDIR"/Metadata/JkUfw.xml
  echo "jk-ufw удалён. Интерфейс вернётся к стандартной теме."
  exit 0
fi
[ -d "$WWW/themes" ] || { echo "Не найден каталог $WWW/themes — это не поддерживаемая система."; exit 1; }
# старое имя темы из предыдущих версий
rm -rf "$WWW/themes/crimson"
rm -rf "$DST"; mkdir -p "$DST"
cp -R "$HERE/src/opnsense/www/themes/jkufw/build" "$DST/"
chmod -R a+rX "$DST"
cp "$HERE"/src/opnsense/www/js/widgets/JkUfw*.js "$WDIR/"
cp "$HERE"/src/opnsense/www/js/widgets/Metadata/JkUfw.xml "$WDIR/Metadata/"
chmod a+r "$WDIR"/JkUfw*.js "$WDIR"/Metadata/JkUfw.xml
echo "Готово. System > Settings > General > Theme = jkufw, затем Save и Ctrl+F5."
echo "Виджеты: Lobby > Dashboard > карандаш > Add widget > все пункты «jk-ufw: …» (их 10)."
