# Mulgore FM

**When someone types `moo` in chat, you hear a real cow.** Each character has a consistent cow voice. When several players moo together, you hear the whole herd. Only listeners need the addon.

*Русское описание ниже.*

## Features

- **Moos from chat become cow calls.** Say, Yell, General, Trade and custom channels, party, raid and instance chat (leaders and raid warnings included), guild, officer, incoming and sent whispers.
- **One character, one cow voice.** The addon picks one of four voices from the character’s name and realm. With the same voice catalog, listeners hear the same cow across chats and after restarts. The four voices share a catalog of 15 calls.
- **A real herd.** Different players moo at the same time. One player's moos play in the order written, with a short pause between their messages.
- **The way you write matters.**
  - `moo`, `mooo` and `moooo` ask for short, medium and long calls.
  - `moo` asks for a calm call, `MOO` for an angry one, `moOO` for a rising call and `MOoo` for a fading one. Your cow plays its closest recording. Some calls have alternate takes.
  - `moo mooo MOO` asks for three calls in order, the most a single message can trigger.
- **Understands many ways to moo:** Russian `му`, English `moo` and `mu`, German `muh`, French `meuh`, Dutch `boe`. It also catches glued moos (`муму`, `moomoo`), repeated M (`ММУУУУ`, `mmmoo`), Latin look-alikes (`MYYYY`, or `MУУУ` typed with a Latin M).
- **Whole words by default.** `moonlight` and `much` stay quiet unless you turn on **Moo inside words**. The English word `my` stays quiet either way.
- **Moo volume.** The slider runs from 0 to 100 in steps of 10. At 20 you hear the original recording, 50 is the default boost, and 60–100 adds mild overdrive. Setting it to 0 mutes the cows. Turn **Moo sounds** back on to restore your last volume.
- **Spam protection.** With the default settings, up to 11 calls can be playing or waiting across all players (31 at the highest setting). While one character is mooing, anti-spam lets one more message from that character wait.
- **Settings page** in Options > AddOns > Mulgore FM:
  - each chat group can be turned off;
  - your own messages can be turned off;
  - **Test** plays your cow, even with chat reactions disabled, as long as **Moo sounds** is on. **Clear queue** drops waiting calls and stops active ones when the game allows it.
- **Plays on the game’s Sound Effects channel** at your Master and Effects volume. The addon leaves those settings alone. Status and debug messages appear only in your chat window. The addon never sends messages to other players or saves a player list.
- English and Russian interface, chosen by the game client's language.

## How to use

1. Install the addon and fully restart the game.
2. Someone writes `му`, `moo` or `МУУУУУ` in chat, and their cow moos.
3. Open the settings with `/mfm` and press **Test** to hear your own cow.

Commands:

- `/mfm`: open the settings.
- `/mfm test`: play your own cow.
- `/mfm clear` (or `/mfm stop`) clears waiting calls and stops active ones when possible.
- `/mfm status`: version, volume, your cow and counters.
- `/mfm debug` toggles local diagnostics for call selection and skipped messages. Message text and player names are omitted.

## Installation

Install it with the CurseForge app, or download the archive from [GitHub Releases](https://github.com/Ahri-ninetailed/MulgoreFM/releases) and unpack the `MulgoreFM` folder into `World of Warcraft\_forever_\Interface\AddOns`. After installing or updating, **restart the game completely**: `/reload` does not pick up new sound files.

Game version: **WoW Forever**.

## Credits and license

- **Sounds:** recordings by DRAGON-STUDIO and RibhavAgrawal (Pixabay), and Joseph SARDIN, BigSoundBank.com (CC0). The sounds belong to their authors; details are in [SOURCES_AND_LICENSES.md](https://github.com/Ahri-ninetailed/MulgoreFM/blob/main/SOURCES_AND_LICENSES.md) inside the addon.
- **Code:** © 2026 Ahri-ninetailed, All Rights Reserved. See [LICENSE.md](https://github.com/Ahri-ninetailed/MulgoreFM/blob/main/LICENSE.md).

Source code and bug reports: [GitHub](https://github.com/Ahri-ninetailed/MulgoreFM)

---

# Mulgore FM (Русский)

**Когда кто-то пишет в чате `му`, вы слышите настоящее коровье мычание.** У каждого персонажа постоянный голос коровы. Когда несколько игроков мычат одновременно, слышно целое стадо. Аддон нужен только тому, кто хочет слышать звук.

## Возможности

- **«Му» из чата превращается в мычание.** «Сказать», «Крик», General, Trade и свои каналы, группа, рейд и подземелье (включая лидеров и объявления рейда), гильдия, офицеры, входящий и отправленный шёпот.
- **Один персонаж — один голос.** Аддон выбирает один из четырёх голосов по имени персонажа и игровому миру. С одним и тем же набором голосов все слушатели узнают корову персонажа в любом чате и после перезапуска. Всего у четырёх коров 15 реплик.
- **Настоящее стадо.** Разные игроки мычат одновременно. «Му» одного игрока звучат по порядку написания, с короткой паузой между его сообщениями.
- **Важно, как написано.**
  - `му`, `мууу` и `муууууу` задают короткую, среднюю и длинную реплику.
  - `му` задаёт спокойное мычание, `МУ` — сердитое, `мууУУУ` — нарастающее, `МУУууу` — затихающее. Корова сыграет ближайшую по звучанию запись из своего набора. У некоторых реплик есть несколько вариантов.
  - До трёх «му» в сообщении: `му мууу МУУУ` — три реплики подряд.
- **Понимает разные «му»:** русское `му`, английские `moo` и `mu`, немецкое `muh`, французское `meuh`, нидерландское `boe`. Ловит слитные `муму` и `moomoo`, несколько «М» в начале (`ММУУУУ`, `mmmoo`) и похожие латинские буквы: `MYYYY` или `MУУУ` с латинской M.
- **По умолчанию ищет отдельное «му».** `музыка`, `moonlight` и `much` звучат только с включённой настройкой **«Му внутри слов»**. Английское слово `my` молчит в обоих режимах.
- **Громкость мычания.** Ползунок идёт от 0 до 100 с шагом 10. При 20 звучит исходная запись, 50 — усиление по умолчанию, а при 60–100 появляется лёгкий перегруз. На 0 коровы замолкают. Галочка **«Звук коров»** возвращает прежнюю громкость.
- **Защита от спама.** По умолчанию суммарно могут звучать или ждать до 11 реплик от всех игроков, на максимальной настройке — до 31. Пока корова мычит, антиспам пропускает в очередь ещё одно сообщение от того же персонажа.
- **Страница настроек** в Options > AddOns > Mulgore FM:
  - каждую группу чатов можно выключить;
  - свои сообщения можно не озвучивать;
  - **«Тест»** играет вашу корову даже при отключённой реакции на чат, если включён «Звук коров». **«Очистить очередь»** убирает ожидающие реплики и останавливает звучащие, если это позволяет игра.
- **Мычание звучит через канал эффектов игры** и учитывает общую громкость и громкость эффектов. Аддон не меняет эти настройки. Статус и отладку видите только вы в своём окне чата. Аддон не отправляет сообщений другим игрокам и не сохраняет список персонажей.
- Интерфейс на английском и русском, по языку клиента игры.

## Как пользоваться

1. Установите аддон и полностью перезапустите игру.
2. Кто-то пишет в чат `му`, `moo` или `МУУУУУ` — и мычит его корова.
3. Откройте настройки командой `/mfm` и нажмите **«Тест»**, чтобы услышать свою корову.

Команды:

- `/mfm` — настройки.
- `/mfm test` — сыграть вашу корову.
- `/mfm clear` (или `/mfm stop`) — очистить очередь и по возможности остановить звучащие реплики.
- `/mfm status` — версия, громкость, ваша корова и счётчики.
- `/mfm debug` — включить или выключить вывод выбранных реплик и причин пропуска в своём окне чата. Имена и текст сообщений скрыты.

## Установка

Через приложение CurseForge, или скачайте архив из [GitHub Releases](https://github.com/Ahri-ninetailed/MulgoreFM/releases) и распакуйте папку `MulgoreFM` в `World of Warcraft\_forever_\Interface\AddOns`. После установки или обновления **полностью перезапустите игру**: `/reload` не подхватывает новые звуковые файлы.

Версия игры: **WoW Forever**.

## Авторы и лицензия

- **Звуки:** записи DRAGON-STUDIO и RibhavAgrawal (Pixabay), а также Joseph SARDIN, BigSoundBank.com (CC0). Звуки принадлежат их авторам, подробности в файле [SOURCES_AND_LICENSES.md](https://github.com/Ahri-ninetailed/MulgoreFM/blob/main/SOURCES_AND_LICENSES.md) внутри аддона.
- **Код:** © 2026 Ahri-ninetailed, все права защищены. См. [LICENSE.md](https://github.com/Ahri-ninetailed/MulgoreFM/blob/main/LICENSE.md).

Исходный код и сообщения об ошибках: [GitHub](https://github.com/Ahri-ninetailed/MulgoreFM)
