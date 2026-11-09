# Deadlock Disk Keepalive

[Русский](#русский) | [English](#english)

## RU

Небольшой помощник для Windows, который может уменьшить фризы в Deadlock, если они связаны с медленным чтением файлов игры с накопителя.

### В чём проблема

Иногда игра на долю секунды замирает, когда ей нужны данные с SSD. В одном случае проверка показала, что чтение маленького участка файла игры занимало более половины секунды. Когда диск постоянно выполнял небольшие чтения, задержки в тесте стали меньше, а во время двух матчей заметных фризов не было.

Причину задержек конкретного накопителя установить не удалось. У похожих фризов бывают разные причины, поэтому этот способ может помочь не всем. Две игры без фризов ещё не доказывают, что проблема устранена навсегда.

### Как установить

1. Откройте файл [DeadlockDiskKeepalive.zip](DeadlockDiskKeepalive.zip) и распакуйте его.
2. Дважды нажмите на `DeadlockDiskKeepalive.bat`.
3. Дождитесь сообщения «Готово» и закройте окно.
4. Запустите Deadlock и поиграйте как обычно.

Windows может показать предупреждение для скачанного батника. Его исходный код доступен в этом репозитории для проверки.

### Как это работает

После входа в Windows помощник ждёт запуска Deadlock. Пока игра открыта, он примерно каждые 50 миллисекунд считывает небольшой участок её исполняемого файла с диска. При выходе из игры чтение прекращается. Помощник остаётся в ожидании следующего запуска.

Программа сама определяет расположение запущенной игры. Нужны Windows и встроенный Windows PowerShell. Python устанавливать не требуется.

### Как отключить

1. Нажмите **Win + R**.
2. Вставьте `%LOCALAPPDATA%\DeadlockDiskKeepalive` и нажмите Enter.
3. Дважды нажмите `Remove-DeadlockDiskKeepalive.bat`.

Автозапуск будет отключён, фоновое чтение прекратится. Установленные файлы останутся в этой папке. При необходимости их можно удалить вручную.

### Если не помогло

Проверьте, появляется ли файл `keepalive.log` в папке `%LOCALAPPDATA%\DeadlockDiskKeepalive`. Если в нём есть строка `ERROR`, укажите её при обращении за помощью. Лог может содержать путь к установленной игре — просмотрите его перед отправкой.

Фоновое чтение добавляет небольшую нагрузку на диск и работает только при запущенной игре. Оно не исправляет причину медленной работы накопителя. Если другие программы тоже надолго зависают при обращении к диску, стоит отдельно проверить накопитель и подключение.

## EN

A small Windows helper that may reduce Deadlock stutters when they are caused by slow reads from the drive holding the game.

### What is happening

The game can briefly freeze while waiting for data from an SSD. In one investigated case, reading a small part of a game file took more than half a second. Light background reads reduced the measured delays, and the player noticed no stutters during two matches.

The underlying cause of that drive's slow responses remains unknown. Similar stutters can have different causes, so this workaround will not help everyone. Two smooth matches do not prove a permanent fix.

### Installation

1. Open [DeadlockDiskKeepalive.zip](DeadlockDiskKeepalive.zip) and extract it.
2. Double-click `DeadlockDiskKeepalive.bat`.
3. Wait for the “Done” message and close the window.
4. Launch Deadlock and play normally.

Windows may show a warning for a downloaded batch file. You can inspect the source code in this repository.

### How it works

After you sign in to Windows, the helper waits for Deadlock to start. While the game is open, it reads a small part of the game's executable from its drive approximately every 50 milliseconds. Reading stops when you exit the game. The helper then waits for the next launch.

The helper finds the running game's location automatically. It requires Windows and the built-in Windows PowerShell. Python is not required.

### Disable

1. Press **Win + R**.
2. Paste `%LOCALAPPDATA%\DeadlockDiskKeepalive` and press Enter.
3. Double-click `Remove-DeadlockDiskKeepalive.bat`.

Startup is disabled and background reading stops. The installed files remain in that folder and can be deleted manually.

### If it doesn't help

Look for `keepalive.log` in `%LOCALAPPDATA%\DeadlockDiskKeepalive`. If it contains an `ERROR` line, include it when asking for help. The log may contain your game installation path, so review it before sharing.

Background reading adds a small amount of disk activity and runs only while the game is open. It does not repair the underlying cause of slow storage. If other programs also freeze while accessing the drive, investigate the drive and its connection separately.
