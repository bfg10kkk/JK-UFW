# Уведомления в Telegram

Страница **System › Settings › Notifications** (`/ui/jkufw/notify`). Бот присылает:

- **угрозы** из IDS/IPS (Suricata, `/var/log/suricata/eve.json`) с выбором важности: только высокая, высокая и средняя, все.
  Одна и та же сигнатура от одного адреса приходит не чаще раза в 30 минут, пачка событий собирается в одно сообщение;
- **пропал и появился интернет**: шлюз перешёл в состояние «down» и обратно (по данным dpinger). Пока интернета нет,
  сообщение ждёт в очереди и уходит сразу после восстановления с пометкой о задержке;
- **вход в веб-интерфейс** (кто и откуда) и **неудачные попытки** (собираются по адресу, не чаще раза в 15 минут).
  Источник: журнал аудита `/var/log/audit/latest.log`.

Можно включить «без звука». Старые события после включения не присылаются: наблюдатель начинает с конца журналов.

## Настройка

1. В Telegram откройте @BotFather, отправьте `/newbot`, скопируйте токен.
2. Вставьте токен на странице, напишите боту любое сообщение (или добавьте его в группу), нажмите «Найти чат» и выберите чат.
3. «Отправить тест», затем включите переключатель «Уведомления» и «Сохранить».

Межсетевому экрану нужен доступ к `api.telegram.org:443`.

## Как устроено

| Файл | Что делает |
|---|---|
| `src/opnsense/mvc/app/models/OPNsense/JkUfw/Notify.xml`, `Notify.php` | настройки в `config.xml` (`OPNsense/JkUfw/notify`) |
| `src/opnsense/mvc/app/controllers/OPNsense/JkUfw/Api/NotifyController.php` | `/api/jkufw/notify/{get,set,reconfigure,test,chats,status}` |
| `src/opnsense/mvc/app/views/OPNsense/JkUfw/notify.volt` | страница |
| `src/opnsense/scripts/jkufw/notify.py` | наблюдатель: `run` (cron), `test`, `chats`, `status`; состояние в `/var/db/jkufw/notify.json` |
| `src/opnsense/service/conf/actions.d/actions_jkufw.conf` | действия configd `jkufw notify *` |
| `src/etc/inc/plugins.inc.d/jkufw.inc` | задание cron раз в минуту, пока уведомления включены |
| `src/opnsense/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml`, `Menu/Menu.xml` | права доступа и пункт меню |

Проверить вручную на экране: `configctl jkufw notify test`, `configctl jkufw notify status`.

## Попробовать без пересборки образа (под root)

```sh
fetch -o /tmp/try-notify.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-notify.sh
sh /tmp/try-notify.sh                 # или: sh /tmp/try-notify.sh <ветка>
sh /tmp/try-notify.sh --remove        # убрать
```
