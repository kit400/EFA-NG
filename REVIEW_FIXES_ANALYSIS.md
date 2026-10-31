# Анализ пакета патчей `efa-ng-review-fixes` и сравнение с основной реализацией

**Дата анализа:** 31 октября 2026 г.  
**База сравнения:**
- Пакет патчей `efa-ng-review-fixes` (`foreverUA <forever@poduryan.com>`, ветка `review-fixes` поверх `EFA-NG` `e640b5e` и `MailWatch-NG` `1b26b18`)
- Основная реализация в репозиториях `EFA-NG` и `MailWatch-NG` (`v6.0.7`)

---

## 1. Состав папки `efa-ng-review-fixes`

1. `README.txt` — описание 3 коммитов для `EFA-NG` и 9 коммитов для `MailWatch-NG`, а также перечень незакрытых задач в разделе `Не сделано`.
2. `EFA-NG-review-fixes.bundle` и `patches/EFA-NG/`:
   - `0001-fix-firewall-ship-eFa-Firewall-disabled-and-never-au.patch` (`E1`)
   - `0002-fix-release-do-not-announce-versions-that-are-not-pa.patch` (`E3`)
   - `0003-fix-installer-stop-on-EL8-EL9-and-on-unpublished-tes.patch` (`E4`)
3. `MailWatch-NG-review-fixes.bundle` и `patches/MailWatch-NG/`:
   - `0001-fix-lists-scope-single-rule-delete-to-the-user-s-own.patch` (`M1`)
   - `0002-fix-lists-escape-rule-values-for-JS-inside-HTML-attr.patch` (`M2`)
   - `0003-fix-detail-never-show-SPF-DKIM-DMARC-PASS-without-ev.patch` (`M3`)
   - `0004-fix-settings-save-only-the-settings-tab-that-was-pos.patch` (`M4`)
   - `0005-fix-notifications-require-the-session-token-for-dele.patch` (`M5`)
   - `0006-fix-logger-write-dead-letter-events-as-UTF-8-and-rep.patch` (`M6`)
   - `0007-fix-login-close-brute-force-protection-bypasses.patch` (`M7`)
   - `0008-fix-tools-refuse-web-execution-of-CLI-tools-inside-t.patch` (`M8`)
   - `0009-fix-notifications-send-broadcasts-from-MAILWATCH_FRO.patch` (`P1`)

---

## 2. Что уже было реализовано полнее в нашей основной ветке

Пункты, отмеченные в `efa-ng-review-fixes/README.txt` как **«Не сделано»**, уже выполнены в нашей реализации:

1. **GPG-подпись всех RPM-пакетов и метаданных репозитория (`E2`)**:
   - Сгенерирован ключ RSA-4096 `EFA-NG Release Signing Key <security@efa-ng.space.ua>`, подписаны все 126 пакетов (`rpmsign --addsign`) и `repodata/repomd.xml.asc`, собраны актуальные пакеты `eFa-6.0.7` и `MailWatch-6.0.7`, включены `gpgcheck=1` и `repo_gpgcheck=1`.
2. **Контроль ошибок в `eFa-Migrate` (`E5`)**:
   - Добавлен подсчёт ошибок `mig_errors` и проверка `PIPESTATUS` на каждом этапе миграции БД и файлов.
3. **Исключение сетей RFC1918 из дефолтного `LOGIN_WHITELIST_IPS` (`M7`)**:
   - По умолчанию оставлены только `127.0.0.1, ::1`.
4. **Сессионная безопасность и фильтры (`P2`, `P3`, `P4`)**:
   - Устранено двойное экранирование апострофа `'` в `SessionGuard.php`, добавлено скользящее продление cookie `PHPSESSID` синхронно с `users.login_expiry`, закрыта SQL-инъекция через префикс `!` в `filter.inc.php`.
5. **Полный отказ от инлайн-JS в `lists.php` (`M2`) и переход на `POST`-формы в `system_notifications.php` (`M5`)**:
   - В `lists.php` применены `JSON_HEX_*` и делегирование событий через `data-*` атрибуты; в `system_notifications.php` действия `delete/toggle/broadcast` переведены с `GET` на `POST` с проверкой `checkFormToken()`.
6. **Частота реплея Dead-Letter очереди (`M6`)**:
   - Запуск `mailwatch_replay_failed_events.php` настроен каждые 5 минут в `/etc/cron.d/msre_reload` (дополнительно к ежедневному запуску).

---

## 3. Интегрированные улучшения из `efa-ng-review-fixes`

Следующие 6 точечных решений из `efa-ng-review-fixes` перенесены и объединены с нашей реализацией:

1. **Автоматическое восстановление серверов со старым дефолтным `firewall.conf` (`updates/update.sh`)**:
   - Сверка `sha256sum /etc/eFa/firewall.conf` с тремя хешами старых дефолтных конфигураций (`960d50...`, `f702cd...`, `f0a594...`). Если конфиг не менялся администратором, создаётся резервная копия `/etc/eFa/firewall.conf.old-default`, подставляется новый безопасный дефолт (`enabled: false`), удаляется таблица `inet efa` и включается `firewalld`.
2. **Чистое удаление таблицы `inet efa` при выключенном `eFa-Firewall` (`disable_efa_firewall`) и флаг `--force`**:
   - В выключенном состоянии `eFa-Firewall` удаляет таблицу `inet efa` (`nft delete table inet efa`), не перекрывая правила `firewalld` таблицей с `policy accept`. Добавлен аргумент `--force`.
3. **Проверка доступности репозиториев `testing`/`dev` в `build/build.bash` и актуализация `README.md`**:
   - В `README.md` убраны упоминания поддержки EL9 / CentOS Stream 9.
   - В `build/build.bash` добавлена функция `check_repo()`, проверяющая наличие `repomd.xml` перед включением `efa-ng-testing` или `efa-ng-dev`.
4. **Уточнения в `parse_email_auth_results()` и `conf.php.example` (`M3`)**:
   - `SPF_HELO_PASS` больше не даёт `SPF = PASS` сам по себе (только `SPF_PASS`).
   - Правило `DKIM_SIGNED` без `DKIM_VALID` выставляет статус `NEUTRAL`.
   - Добавлена поддержка опциональной константы `AUTHSERV_ID` в `conf.php.example` и `functions.php`.
5. **Сериализация параллельных попыток входа с одного IP через `GET_LOCK` (`checklogin.php`, `functions.php`, `M7`)**:
   - В `checklogin.php` добавлена блокировка `SELECT GET_LOCK('mw_login_' . md5(getHTTPClientIP()), 10)` с автоматическим снятием в `register_shutdown_function`, исключающая гонку параллельных запросов до записи неудачи в БД.
   - `clear_login_failures()` принимает как одно имя пользователя, так и массив (`[$myusername, $_POST['myusername'] ?? '']`), чтобы очищать неудачи и для введённого, и для канонического (LDAP/IMAP) логина.
6. **Точечный `git add` и флаг `--allow-unpackaged` в `tools/release.sh` (`E3`)**:
   - В `tools/release.sh` вместо `git add -A` индексируются только релизные файлы, чтобы исключить случайное попадание временных файлов в релизный коммит.
