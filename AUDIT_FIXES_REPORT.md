# Отчёт о выполненной работе по результатам аудита безопасности EFA-NG и MailWatch-NG

**Дата выполнения:** 30–31 октября 2026 г.  
**Версия релиза:** `v6.0.7` (`eFa-6.0.7-12.eFa.el10.noarch`, `MailWatch-6.0.7-1.eFa.el10.noarch`, `php8.4-8.4.27-2.el10.x86_64`)  
**Репозитории:**
- **EFA-NG:** коммит `3f1dd77` (ветка `main`, тег `v6.0.7`)
- **MailWatch-NG:** коммит `062cabb` (ветка `main`, тег `v6.0.7`)

---

## 1. Сводная таблица выполненных задач

| Код задачи | Приоритет | Компонент / Файлы | Описание проблемы и выполненного исправления | Статус |
| :--- | :---: | :--- | :--- | :---: |
| **HARDCODED-IP** | **P0 (Первоочередная)** | `eFa-Firewall`, `firewall.conf.default`, `eFa-Migrate`, `conf.php`, `geoip_update.php`, `settings.php` | Полностью удалены захардкоженные реальные IP-адреса и подсети автора (`195.230.150.*`, `212.1.66.158`, `94.101.42.162`, `185.239.185.200`, `77.235.167.209`) из `get_default_config()` и примеров конфигурации. | ✅ Выполнено |
| **TASK-E1** | **P0** | `eFa-Firewall`, `firewall.conf.default`, `eFa5.spec`, `eFa-Commit` | Отключено автоприменение демо-файрвола при установке/обновлении RPM (`"enabled": false`, `"geoip.enabled": false`), удалены дефолтные страновые блокировки (`RU/CN/BR`, `UA/US/DE`), добавлено автосохранение IP текущей SSH-сессии (`ensure_ssh_session_admin`), загрузка зон `ipdeny.com` переведена на HTTPS, устранён конфликт `firewalld` и `nftables`. | ✅ Выполнено |
| **TASK-M1** | **P0** | `mailscanner/lists.php` | Устранены обход авторизации и SQL-инъекция второго порядка в `delete` и `add`: добавлена сверка с сессионными фильтрами (`$user_filter`, `$to_domain_filter`, `$_SESSION['global_list']`) и экранирование через `safe_value()`. | ✅ Выполнено |
| **TASK-M2** | **P0** | `mailscanner/lists.php` | Устранена Stored XSS при рендеринге таблицы правил: в `json_encode()` добавлены флаги `JSON_HEX_TAG \| JSON_HEX_AMP \| JSON_HEX_APOS \| JSON_HEX_QUOT`, инлайн-обработчики `onclick`/`onchange` заменены на `data-*` атрибуты и делегированные слушатели событий (`bindTableDelegatedEvents`). | ✅ Выполнено |
| **TASK-M3** | **P0** | `mailscanner/functions.php` | Устранены ложные статусы `PASS` для SPF, DKIM и DMARC в `parse_email_auth_results()` и `format_email_auth_badge()`: убраны фолбэки на `PASS` по умолчанию и по одному наличию заголовка `DKIM-Signature` / правила `DKIM_SIGNED`; учитываются только локальные правила SpamAssassin и заголовки `Authentication-Results` от доверенного локального `authserv-id`. | ✅ Выполнено |
| **TASK-E2** | **P0** | `build/build.bash`, `build_all_rpms.sh`, `RPM-GPG-KEY-EFA-NG` | Сгенерирован RSA-4096 GPG-ключ (`EFA-NG Release Signing Key <security@efa-ng.space.ua>`), подписаны все 126 RPM-пакетов в репозитории и метаданные `repodata/repomd.xml.asc`, в `efa-ng.repo` включены `gpgcheck=1` и `repo_gpgcheck=1`. | ✅ Выполнено |
| **TASK-E3** | **P1** | `build_all_rpms.sh`, `eFa5.spec`, `MailWatch.spec`, `tools/release.sh` | Синхронизированы версии `6.0.7` между `version.json` и RPM-пакетами; в `build_all_rpms.sh` включён `set -euo pipefail` (остановка при ошибке сборки) и автоматическая упаковка `eFa-6.0.7.tar.gz` и `MailWatch-6.0.7.tar.gz`. | ✅ Выполнено |
| **TASK-M4** | **P1** | `mailscanner/settings.php` | Разделено сохранение вкладок `save_security_settings` и `save_general_settings`, чтобы сохранение общих настроек не сбрасывало `LOGIN_PROTECTION_ENABLED`. | ✅ Выполнено |
| **TASK-M5** | **P1** | `mailscanner/system_notifications.php` | Действия `delete`, `toggle` и `broadcast` переведены с `GET`-ссылок на `POST`-формы с обязательной проверкой CSRF-токена `checkFormToken()`. | ✅ Выполнено |
| **TASK-M6** | **P2** | `MailScanner_perl_scripts/MailWatch.pm`, `cron/msre_reload.cron` | В `_escape_json_str()` добавлена нормализация `fix_latin()` и экранирование не-ASCII символов в `\uXXXX` для гарантированно валидного JSON в dead-letter очереди; в `/etc/cron.d/msre_reload` добавлен запуск `mailwatch_replay_failed_events.php` каждые 5 минут. | ✅ Выполнено |
| **TASK-M7** | **P2** | `mailscanner/functions.php`, `mailscanner/checklogin.php` | Из дефолтного `LOGIN_WHITELIST_IPS` исключены приватные сети RFC1918 (оставлены `127.0.0.1, ::1`); `clear_login_failures()` очищает счётчик только для пары `(IP, username)`, исключая обход блокировки через вход под другим аккаунтом. | ✅ Выполнено |
| **TASK-M8** | **P2** | `mailscanner/tools/generate_test_traffic.php`, `update_geoip.php` | Добавлена проверка `if (PHP_SAPI !== 'cli') { http_response_code(403); exit(...); }` в начало обоих CLI-скриптов. | ✅ Выполнено |
| **TASK-E4** | **P2** | `build/build.bash` | Зафиксирована явная проверка поддержки EL10 (с понятным сообщением об ошибке на EL8/EL9) и удалена принудительная установка дефолтного пароля `root:eFaPr0j3ct` в Kickstart-режиме. | ✅ Выполнено |
| **TASK-E5** | **P2** | `eFa-Migrate` | Добавлен подсчёт ошибок `mig_errors` и проверка кодов возврата `PIPESTATUS` на каждом этапе миграции БД и rsync, с возвратом ненулевого кода при ошибках. | ✅ Выполнено |
| **TASK-P1** | **P3** | `mailscanner/notifications.inc.php` | Захардкоженный адрес `postmaster@efa-test.localdomain` заменён на динамический (`MAILWATCH_FROM_ADDR` или `postmaster@<hostname>`). | ✅ Выполнено |
| **TASK-P2** | **P3** | `mailscanner/SessionGuard.php` | Устранено двойное экранирование апострофа `'` в имени пользователя (`safe_value(stripslashes((string)$username))`). | ✅ Выполнено |
| **TASK-P3** | **P3** | `mailscanner/SessionGuard.php` | В `SessionGuard::updateExpiry()` добавлено скользящее продление браузерной cookie `PHPSESSID` синхронно с `users.login_expiry` и учёт `SESSION_TIMEOUT` из таблицы `system_settings`. | ✅ Выполнено |
| **TASK-P4** | **P3** | `mailscanner/filter.inc.php` | В `Filter::getConditionClause()` и `Filter::Load()` закрыта возможность произвольной SQL-подстановки через префикс `!`: разрешён только строгий белый список функций даты (`CURRENT_DATE()`, `CURDATE()`, `NOW()`, `DATE_SUB(...)`, `DATE_ADD(...)`) и колонок, а все строковые значения экранируются через `safe_value()`. | ✅ Выполнено |

---

## 2. Детали ключевых изменений

### 2.1. Очистка захардкоженных IP и безопасность файрвола (`eFa-Firewall`, `TASK-E1`)
- В `rpmbuild/SOURCES/eFa-5.0.0/eFa/eFa-Firewall`:
  - В `get_default_config()` список `admins` сокращён до локального петлевого интерфейса (`127.0.0.1`, `::1`); списки `trusted_hosts`, `web_access`, `mail_relays`, `blacklist`, `geoip.blacklist_countries` и `geoip.web_allow_countries` по умолчанию пусты (`[]`), а флаги `enabled` и `geoip.enabled` установлены в `False`.
  - Добавлены функции `detect_ssh_client_ip()` и `ensure_ssh_session_admin(cfg)`: при включении файрвола из интерактивной SSH-сессии IP-адрес администратора из `SSH_CLIENT` / `SSH_CONNECTION` автоматически добавляется в `admins`, предотвращая потерю доступа к серверу.
  - При `enabled: False` функция `apply_firewall()` не отключает `firewalld` и не перезаписывает системный `/etc/sysconfig/nftables.conf`.
  - В `fetch_country_zone()` протокол загрузки списков подсетей изменён с `http://www.ipdeny.com/...` на `https://www.ipdeny.com/...`.
- В `rpmbuild/SPECS/eFa5.spec` (`%post`):
  - При первичной установке `/etc/eFa/firewall.conf.default` копируется в `/etc/eFa/firewall.conf` без автоматического вызова `eFa-Firewall --apply`.
  - При обновлении пакета `eFa-Firewall --apply` вызывается только в том случае, если администратор ранее явно включил файрвол (`"enabled": true` в `/etc/eFa/firewall.conf`).

### 2.2. Безопасность Allowlist / Blocklist (`mailscanner/lists.php`, `TASK-M1`, `TASK-M2`)
- **Авторизация и защита от SQLi (`TASK-M1`)**:
  - При добавлении записи (`add`) проверяется, что пользователь с ролью `U` может создавать правила только для своих адресов из `$user_filter`, а администратор домена (`D`) — только для своих доменов из `$to_domain_filter`.
  - При удалении записи (`delete`) выборка и удаление выполняются с условием `AND (` . `$_SESSION['global_list']` . `)`, дополнительной проверкой принадлежности адреса/домена текущей сессии и обязательным экранированием `$safe_del_to = safe_value($del_to)` и `$safe_del_domain = safe_value($del_domain)`.
- **Защита от Stored XSS (`TASK-M2`)**:
  - Сериализация массивов `$whitelists`, `$blacklists` и `$_SESSION['token']` в `<script>` выполняется с флагами `JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT`.
  - Из HTML-шаблона строк таблицы удалены инлайн-атрибуты `onclick` и `onchange`, в которые ранее подставлялся `escapeJs(r.from)`. Вместо них используются `data-key` и `data-sender` с `escapeHtml()`, обрабатываемые делегированным слушателем `bindTableDelegatedEvents()`.

### 2.3. Честная проверка SPF / DKIM / DMARC (`mailscanner/functions.php`, `TASK-M3`)
- В `parse_email_auth_results()`:
  - Удалены строки, устанавливавшие `$spfStatus = 'PASS'`, `$dkimStatus = 'PASS'` и `$dmarcStatus = 'PASS'` при отсутствии результатов проверки.
  - Удалена установка `$dkimStatus = 'PASS'` при обнаружении заголовка `DKIM-Signature:` или правила `DKIM_SIGNED` (теперь из `DKIM-Signature:` извлекается только метаинформация о домене `d=...`).
  - Первичным источником вердикта являются правила SpamAssassin (`SPF_PASS`, `SPF_FAIL`, `SPF_SOFTFAIL`, `DKIM_VALID`, `DKIM_INVALID`, `DMARC_PASS`, `DMARC_FAIL`, `DMARC_REJECT`, `DMARC_QUAR`).
  - Заголовок `Authentication-Results` учитывается только если его `authserv-id` совпадает с локальным хостом шлюза.

### 2.4. Подпись пакетов и репозитория (`TASK-E2`, `TASK-E3`)
- Сгенерирован ключ `EFA-NG Release Signing Key <security@efa-ng.space.ua>` (отпечаток `43E577A587B5B19C2275CC6E91B432C0C8E1758A`).
- Публичный ключ сохранён в `rpm/efa-ng/RPM-GPG-KEY-EFA-NG` и `rpm/efa-ng/centos10/release/repodata/repomd.xml.key`.
- Все 126 RPM-пакетов в `rpm/efa-ng/centos10/release/` подписаны через `rpmsign --addsign`, метаданные репозитория пересозданы через `createrepo_c` и подписаны отсоединенной подписью `repodata/repomd.xml.asc`.

---

## 3. Верификация и статус серверов

### 3.1. Автоматические тесты и статический анализ
- **PHPUnit 9.6.36** (`PHP 8.4.27`): `175 tests, 639 assertions — OK`
- **PHPStan**: `[OK] No errors`
- **Синтаксический контроль**:
  - `python3 -m py_compile` (`eFa-Firewall`) — `OK`
  - `bash -n` (`build.bash`, `eFa-Migrate`, `eFa-Commit`, `build_all_rpms.sh`, `release.sh`) — `OK`
  - Поиск захардкоженных IP автора в `rpmbuild/SOURCES/` и `mailscanner/` — `0 совпадений (CLEAN)`

### 3.2. Статус окружений (`Local`, `efa-test`, `efa-fresh`)

| Узел | IP / Хост | Версия PHP | Версия `eFa` RPM | Версия `MailWatch` RPM | Статус сервисов (`mariadb`, `postfix`, `mailscanner`, `php-fpm`, `httpd`, `sqlgrey`, `clamd@scan`) |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Local (Dev)** | `EFA-NG-Dev.ukrpack.net` | `8.4.27-2.el10` | Исходники `6.0.7` | Исходники `6.0.7` | Сборка и тесты `OK` |
| **efa-test** | `195.230.150.68` | `8.4.27-2.el10` | `eFa-6.0.7-12.eFa.el10.noarch` | `MailWatch-6.0.7-1.eFa.el10.noarch` | Все 7 сервисов `active` |
| **efa-fresh** | `195.230.150.80` | `8.4.27-2.el10` | `eFa-6.0.7-12.eFa.el10.noarch` | `MailWatch-6.0.7-1.eFa.el10.noarch` | Все 7 сервисов `active` |
