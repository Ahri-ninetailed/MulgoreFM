# Источники и права · Mulgore FM

Проверено **11 ноября 2026 года** по карточкам издателей и действующим на момент проверки текстам условий. Реестр охватывает все восемь MP3 и шесть WAV, включая материалы, не попавшие в библиотеку.

**Статус полной сборки для публичного распространения: UNVERIFIED — NOT CLEARED FOR PUBLIC RELEASE.** Одиннадцать игровых файлов происходят из Pixabay: семь исходных и четыре, добавленные в версии аддона 0.4.0. Ещё четыре взяты из документированной записи CC0. Статус относится к способу распространения готового аддона и отдельной библиотеки. На самих восьми карточках Pixabay явно указана Pixabay Content License.

## Восемь исходных MP3

Идентификация основана на совпадающих ID, названиях и именах авторов в названиях файлов и карточках. Длительности согласуются с округлённым временем на сайте. Теги контейнеров этих локальных MP3 не содержат сертификатов. Хеши ниже идентифицируют именно пользовательские копии. Побайтовое сравнение с новыми загрузками с сайта и проверка всей цепочки прав авторов не проводились.

| Локальный файл | Автор в карточке | Опубликован | Отбор | Карточка с лицензией |
| --- | --- | --- | --- | --- |
| `ribhavagrawal-cow-mooing-type-03-293302.mp3` | RibhavAgrawal | 2025-01-28 | cow_03 · 4 OGG (2 + 2 в 0.4.0) | [Pixabay · 293302](https://pixabay.com/sound-effects/nature-cow-mooing-type-03-293302/) |
| `ribhavagrawal-cow-mooing-type-04-293297.mp3` | RibhavAgrawal | 2025-01-28 | cow_02 · 4 OGG (2 + 2 в 0.4.0) | [Pixabay · 293297](https://pixabay.com/sound-effects/nature-cow-mooing-type-04-293297/) |
| `scottishperson-sound-effect-cow-mooing-356517.mp3` | ScottishPerson | 2025-06-09 | Резерв | [Pixabay · 356517](https://pixabay.com/sound-effects/nature-sound-effect-cow-mooing-356517/) |
| `dragon-studio-cow-moo-339729.mp3` | DRAGON-STUDIO | 2025-05-12 | cow_01 · 3 OGG | [Pixabay · 339729](https://pixabay.com/sound-effects/nature-cow-moo-339729/) |
| `dragon-studio-cow-moo-390282.mp3` | DRAGON-STUDIO | 2025-08-18 | Резерв | [Pixabay · 390282](https://pixabay.com/sound-effects/nature-cow-moo-390282/) |
| `universfield-cow-moo-122255.mp3` | Universfield | 2022-10-09 | Резерв | [Pixabay · 122255](https://pixabay.com/sound-effects/nature-cow-moo-122255/) |
| `dragon-studio-cow-moo-1-472361.mp3` | DRAGON-STUDIO | 2026-01-26 | Исключён · AI generated | [Pixabay · 472361](https://pixabay.com/sound-effects/nature-cow-moo-1-472361/) |
| `u_jd81cxyq22-cow-mooing-343423.mp3` | u_jd81cxyq22 | 2025-05-19 | Резерв | [Pixabay · 343423](https://pixabay.com/sound-effects/nature-cow-mooing-343423/) |

Для каждой строки таблицы, включая резервные MP3, статус допуска именно к публичной раздаче извлекаемых звуков — **UNVERIFIED — NOT CLEARED FOR PUBLIC RELEASE**. Указание «AI generated» у 472361 послужило основанием исключить его из-за требований к натуральности. Отсутствие такой отметки у остальных записей само по себе не удостоверяет обстоятельства полевой записи.

## Дополнение 0.4.0: четыре реплики

Добавлены 11 ноября 2026 года из пакета `MulgoreFM_Update` (`AUDITION_MANIFEST.csv`). Все четыре — производные тех же двух записей RibhavAgrawal с Pixabay, лицензия Pixabay Content License. Статус перенесён из приложенного CSV: **UNVERIFIED — NOT CLEARED FOR PUBLIC RELEASE**. Размеры и SHA-256 проверены при импорте и совпадают с CSV.

| OGG | Источник | Обработка (из CSV) | с | SHA-256 |
| --- | --- | --- | ---: | --- |
| `Sounds/cow_02/calm_short_01.ogg` | Pixabay 293297 | audition; original continuous release restored | 1,344989 | `1be50964d331ceba2fea8c7ce531c293975b8b4e4dd78aaf3eeb9156c83c9398` |
| `Sounds/cow_02/angry_medium_01.ogg` | Pixabay 293297 | audition; pitch-synchronous derivative of the same take | 1,540000 | `902f2dd787afd415212cd6a8ec8af74e31ab8c47a88611e08dd023675522f464` |
| `Sounds/cow_03/calm_short_02.ogg` | Pixabay 293302 | audition; pitch-synchronous derivative of the same take | 1,300000 | `1999c087728307461e40153e0bf44efea25d3f816faa8d073af4a755338f10e3` |
| `Sounds/cow_03/angry_medium_01.ogg` | Pixabay 293302 | audition; pitch-synchronous derivative of the same take | 1,600000 | `9857a2fcd0daece59b3c7816df04578946a931aa813666e347eb23f8d2d93cac` |

## Что разрешает лицензия Pixabay

Раздел 5 условий разрешает использовать и изменять материалы, в том числе коммерчески. Он ограничивает распространение материала в самостоятельном виде, когда творческий вклад отсутствует и содержимое по существу остаётся исходным. Интерактивная связь звука с игровым чатом — часть новой работы. При этом OGG в каталоге аддона можно извлечь отдельно. Обрезка пауз, выравнивание уровня и перекодирование оставляют сами крики узнаваемыми. Эти обстоятельства не позволяют в рамках этой проверки подтвердить допуск к публичному релизу. [Полные условия, § 5](https://pixabay.com/service/terms/) · [Краткое изложение лицензии](https://pixabay.com/service/license-summary/)

Этот пакет служит для частной технической работы владельца. Не публикуйте ZIP, отдельную библиотеку или сравнительное превью как самостоятельный набор стоковых звуков. До публикации аддона на CurseForge зафиксируйте основание для поставки этих OGG в извлекаемом виде, например разрешение обладателя соответствующих прав. Если такого основания нет, замените затронутые файлы собственными записями или записями с подтверждённой CC0. После замены обновите каталог, длительности и хеши. Лицензия будущего Lua-кода не переоформляет права на вложенные звуки.

## Резервные WAV BigSoundBank

Все шесть карточек называют автора **Joseph SARDIN** и помечены CC0. Общая страница автора указывает CC0 1.0 Universal и прямо разрешает изменение и распространение. У файлов также совпадают внутренние идентификаторы `originator_reference` и тег прав. Запись 0546 описывает пять зовов одной коровы на открытом воздухе. [Условия BigSoundBank](https://bigsoundbank.com/licenses.html) · [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)

| Исходный WAV | Статус в библиотеке | Авторская карточка |
| --- | --- | --- |
| `ANMLFarm_Cow moos (ID 0546)_BigSoundBank.com.wav` | Источник 4 OGG | [BigSoundBank · 0546](https://bigsoundbank.com/cow-moos-s0546.html) |
| `ANMLFarm_Cow moos 2 (ID 2382)_BigSoundBank.com.wav` | Повтор фразы из 0546 | [BigSoundBank · 2382](https://bigsoundbank.com/cow-moos-2-s2382.html) |
| `ANMLFarm_Cow moos 3 (ID 2383)_BigSoundBank.com.wav` | Повтор фразы из 0546 | [BigSoundBank · 2383](https://bigsoundbank.com/cow-moos-3-s2383.html) |
| `ANMLFarm_Cow moos 4 (ID 2384)_BigSoundBank.com.wav` | Повтор фразы из 0546 | [BigSoundBank · 2384](https://bigsoundbank.com/cow-moos-4-s2384.html) |
| `ANMLFarm_Cow moos 5 (ID 2385)_BigSoundBank.com.wav` | Повтор фразы из 0546 | [BigSoundBank · 2385](https://bigsoundbank.com/cow-moos-5-s2385.html) |
| `ANMLFarm_Cow moos 6 (ID 2386)_BigSoundBank.com.wav` | Повтор фразы из 0546 | [BigSoundBank · 2386](https://bigsoundbank.com/cow-moos-6-s2386.html) |

**Пригодная к публичному использованию часть по источнику** — четыре OGG в `Sounds/cow_04/`, полученные только из 0546. Кредит для README: «Additional sounds: Joseph SARDIN — BigSoundBank.com». Для внутренней сборки также укажите RibhavAgrawal и DRAGON-STUDIO с карточками из таблицы. У `PROFILE_PREVIEW.mp3` тот же статус частной проверки, что и у полной библиотеки, поскольку в него вошли все четыре профиля.

## Контрольные суммы полученных источников

| ID исходника | SHA-256 |
| --- | --- |
| 293302 | `750c03cef72a4ecc5991433a99ca5b593d0177ceb72a652b4d75ca1e00dffc38` |
| 293297 | `3ac0c1bcb9293a1b47d4d22ec200664a08eee100a3192c9bf01afd37c1862580` |
| 356517 | `38d8c93b7fab2b891e8a8e86f79acb5de1005e85b67513f0544d702216db793e` |
| 339729 | `38ecb3cdd9904a16931c0a482665ad6cb3a740793d30f38c5b4dc2f0070ab0f3` |
| 390282 | `ea4b094d4e465628b4eb8dd8148a234309ecaacf50cd902938968c8b4706aad0` |
| 122255 | `7a69e0fb3c1b200be0b45f4e7753cd0c4b11fb23f23c34b83fd60f47ed9faf87` |
| 472361 | `f85f493700612a68c3ebae582267c53f918fa55bb6fdffec12fb706e9aa449de` |
| 343423 | `493bd6815976130574c805ccae842a42b72235bd9c162d6526487dd121e88072` |
| 0546 | `a76075ae826b7a38c26ebadbdd4526ba156c1970247c89afb1d0587b73f6f4d0` |
| 2382 | `e48272814de3d95be94e2a63cd9828d56ca7464138d712703993e67b41e389c1` |
| 2383 | `58f0eaf85c63409f46e8f3f2b3cc14797f9a1c15bd9e8ab4cdd3809c94e0efaa` |
| 2384 | `c0e0ef32ba729609f52c180bd1418665c625a2e1aa6315f7a6ebbdb241cb92f1` |
| 2385 | `9094cdb4b7c544a55f7ae76b61d359ff0e20c4c86ef30eec835d7d855c8d610d` |
| 2386 | `17e5d51efb97adc9f284d1d5f5481d150a80c01c4141fe7f28591ba6e590f02c` |

