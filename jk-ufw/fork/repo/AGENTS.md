# Указания для помощников по коду в репозитории @PRODUCT@

- Это система файрвола на FreeBSD: PHP/Phalcon MVC в `src/opnsense/mvc`, служебные скрипты в
  `src/opnsense/scripts`, действия configd в `src/opnsense/service/conf/actions.d`, шаблоны конфигурации
  в `src/opnsense/service/templates`.
- Название продукта для пользователя задаётся в `Mk/version.mk` (`CORE_PRODUCT`). Внутренние имена
  (пространства имён PHP, каталог `/usr/local/opnsense`, имя пакета, ключи конфигурации) не переименовывать:
  от них зависят сборка, обновления и миграции.
- Не удалять и не изменять уведомления об авторских правах и файл `LICENSE` — этого требует лицензия BSD 2-Clause.
- Тема интерфейса: исходники в `jk-ufw/overrides` и `jk-ufw/assets`, собранная тема в
  `src/opnsense/www/themes/jkufw/build`. Виджеты дашборда: `src/opnsense/www/js/widgets/JkUfw*.js`
  и `Metadata/JkUfw.xml`.
- После слияния изменений из основной ветки исходного проекта запускать `sh jk-ufw/fork/rebrand-core.sh .`
  и проверять `git diff`.
- Новые файлы в пакете добавлять в `plist` (`make plist-fix`).
- Перед коммитом: `make lint`, `make style`.
