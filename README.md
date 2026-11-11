# Mulgore FM

**When someone writes a standalone "moo" in chat, your game plays a real cow mooing.** Every player always has the same cow voice, the way they write sets the length and mood of the moo, and when several players moo at once you hear a whole herd.

*Русское описание ниже.*

## Features

- **Moos from chat become cow calls.** Say, Yell, General, Trade and custom channels, party, raid and instance chat (leaders and raid warnings included), guild, officer, incoming and sent whispers.
- **One player, one cow.** Four cow voices with 15 recordings. Each player always gets the same cow, in every chat, after every restart and for everyone who has the addon: the cow is picked from the player's name, nothing is stored.
- **A real herd.** Different players moo at the same time. One player's moos play in the order written, with a short pause between their messages.
- **The way you write matters.**
  - Length: `му` is short, `мууу` medium, `муууууу` long.
  - Mood: `МУУУ` in capitals is loud and angry, `мууУУУ` rises, `МУУууу` fades away, lowercase is calm.
  - Up to three moos per message: `му мууу МУУУ` plays three calls in a row.
- **Understands many ways to moo:** Russian `му`, English `moo` and `mu`, German `muh`, French `meuh`, Dutch `boe`. It also catches glued moos (`муму`, `moomoo`), repeated M (`ММУУУУ`, `mmmoo`), Latin look-alikes (`MYYYY`, or `MУУУ` typed with a Latin M) and up to three moos in one message.
- **Never fires on normal words.** `музыка`, `moonlight`, `my` and `much` stay silent. The **Moo inside words** option, off by default, lets them moo too.
- **Moo volume slider, 10 to 100.** 20 is the recordings as they are, 50 (default) is about twice as loud, 60 to 100 louder still with a slight overdrive, like a cow at full voice. The **Moo sounds** checkbox mutes all cows at once and remembers your volume.
- **Spam protection.** A limit on how many calls can sound or wait at once (default 10, up to 30), and an anti-spam rule: a player who floods "moo" gets one waiting message, the rest are dropped.
- **Settings page** in Options > AddOns > Mulgore FM:
  - each chat group can be turned off;
  - your own messages can be turned off;
  - a **Test** button plays your own cow, **Clear queue** stops all cows at once.
- **Plays on the game's Sound Effects channel** and follows your Master and Effects volume. The addon never changes game settings, never writes to chat and keeps no list of players.
- English and Russian interface, chosen by the game client's language.

## How to use

1. Install the addon and fully restart the game.
2. Someone writes `му`, `moo` or `МУУУУУ` in chat, and their cow moos.
3. Open the settings with `/mfm` and press **Test** to hear your own cow.

Commands:

- `/mfm`: open the settings.
- `/mfm test`: play your own cow.
- `/mfm clear`: stop all cows.
- `/mfm status`: version, volume, your cow and counters.
- `/mfm debug`: show which call was picked, without message text or names.

## Installation

Install it with the CurseForge app, or download the archive from [GitHub Releases](https://github.com/Ahri-ninetailed/MulgoreFM/releases) and unpack the `MulgoreFM` folder into `World of Warcraft\_forever_\Interface\AddOns`. After installing or updating, **restart the game completely**: `/reload` does not pick up new sound files.

Game version: **WoW Forever**.

## Credits and license

- **Sounds:** recordings by DRAGON-STUDIO and RibhavAgrawal (Pixabay), and Joseph SARDIN, BigSoundBank.com (CC0). The sounds belong to their authors; details are in `SOURCES_AND_LICENSES.md` inside the addon.
- **Code:** © 2026 Ahri-ninetailed, All Rights Reserved. See `LICENSE.md`.

Source code and bug reports: [GitHub](https://github.com/Ahri-ninetailed/MulgoreFM)

---

# Mulgore FM (Русский)

**Когда кто-то пишет в чате отдельное «му», в игре звучит настоящее коровье мычание.** У каждого игрока всегда один и тот же голос коровы, от написания зависят длина и настроение «му», а когда мычат несколько игроков сразу, слышно целое стадо.

## Возможности

- **«Му» из чата превращается в мычание.** «Сказать», «Крик», General, Trade и свои каналы, группа, рейд и подземелье (включая лидеров и объявления рейда), гильдия, офицеры, входящий и отправленный шёпот.
- **Один игрок — одна корова.** Четыре голоса, 15 записей. Каждый игрок всегда получает одну и ту же корову в любом чате, после любого перезапуска и у всех, у кого стоит аддон. Корова выбирается по имени игрока, ничего не сохраняется.
- **Настоящее стадо.** Разные игроки мычат одновременно. «Му» одного игрока звучат по порядку написания, с короткой паузой между его сообщениями.
- **Важно, как написано.**
  - Длина: `му` — короткое, `мууу` — среднее, `муууууу` — длинное.
  - Настроение: `МУУУ` заглавными — громко и сердито, `мууУУУ` — нарастает, `МУУууу` — затихает, строчные — спокойно.
  - До трёх «му» в сообщении: `му мууу МУУУ` — три реплики подряд.
- **Понимает разные «му»:** русское `му`, английские `moo` и `mu`, немецкое `muh`, французское `meuh`, нидерландское `boe`. Ловит слитные `муму` и `moomoo`, несколько «М» в начале (`ММУУУУ`, `mmmoo`) и похожие латинские буквы: `MYYYY` или `MУУУ` с латинской M.
- **Не срабатывает на обычные слова.** `музыка`, `moonlight`, `my` и `much` молчат. Галочка **«Му внутри слов»** (по умолчанию выключена) включает мычание и на них.
- **Ползунок «Громкость му», от 10 до 100.** 20 — записи как есть, 50 (по умолчанию) — примерно вдвое громче, 60–100 ещё громче с лёгким перегрузом, как корова в полный голос. Галочка **«Звук коров»** сразу глушит всех коров и запоминает громкость.
- **Защита от спама.** Ограничение на число одновременно звучащих и ожидающих реплик (по умолчанию 10, до 30) и антиспам: у игрока, который заваливает чат «му», ждёт одно сообщение, остальные отбрасываются.
- **Страница настроек** в Options > AddOns > Mulgore FM:
  - каждую группу чатов можно выключить;
  - свои сообщения можно не озвучивать;
  - кнопка **«Тест»** играет вашу корову, **«Очистить очередь»** останавливает всех коров.
- **Звучит через канал звуковых эффектов игры** и подчиняется ползункам «Общая громкость» и «Эффекты». Аддон не меняет настройки игры, ничего не пишет в чат и не хранит списков игроков.
- Интерфейс на английском и русском, по языку клиента игры.

## Как пользоваться

1. Установите аддон и полностью перезапустите игру.
2. Кто-то пишет в чат `му`, `moo` или `МУУУУУ` — и мычит его корова.
3. Откройте настройки командой `/mfm` и нажмите **«Тест»**, чтобы услышать свою корову.

Команды:

- `/mfm` — настройки.
- `/mfm test` — сыграть вашу корову.
- `/mfm clear` — остановить всех коров.
- `/mfm status` — версия, громкость, ваша корова и счётчики.
- `/mfm debug` — какая реплика выбрана, без текста сообщений и имён.

## Установка

Через приложение CurseForge, или скачайте архив из [GitHub Releases](https://github.com/Ahri-ninetailed/MulgoreFM/releases) и распакуйте папку `MulgoreFM` в `World of Warcraft\_forever_\Interface\AddOns`. После установки или обновления **полностью перезапустите игру**: `/reload` не подхватывает новые звуковые файлы.

Версия игры: **WoW Forever**.

## Авторы и лицензия

- **Звуки:** записи DRAGON-STUDIO и RibhavAgrawal (Pixabay), а также Joseph SARDIN, BigSoundBank.com (CC0). Звуки принадлежат их авторам, подробности в файле `SOURCES_AND_LICENSES.md` внутри аддона.
- **Код:** © 2026 Ahri-ninetailed, все права защищены. См. `LICENSE.md`.

Исходный код и сообщения об ошибках: [GitHub](https://github.com/Ahri-ninetailed/MulgoreFM)
