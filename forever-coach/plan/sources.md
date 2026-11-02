# Источники для плана прокачки (WoW Forever)

Обновлено: 2026-11-02. Что откуда взято по фактам — в `changelog.md` (там ссылка у каждой записи). Здесь — список источников по надёжности и для чего каждый годится.

Надёжность по убыванию: **официальное** → **данные клиента** → **база из данных клиента** → **гайд** → **мнение игрока**. Если источники спорят, верь тому, что выше. Всё до запуска — данные беты 1.60.1, после 4 ноября перепроверяй в игре.

## 1. Официальное (Blizzard)

| Источник | Что там | Для чего брали |
|---|---|---|
| [Новость о классах Forever](https://worldofwarcraft.blizzard.com/en-us/news/24301515) (+ [копия на форуме](https://us.forums.blizzard.com/en/wow/t/2367361)) | изменения классов | урон оружия в облике, Хватка природы, Знамение ясности, Revive |
| [Заметки разработчиков беты](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-8/2360696) | хотфиксы по датам | Полосование на 20, Tiger's Fury убран, Excavation Site 26–31, опыт подземелий |

## 2. Данные клиента и базы

| Источник | Что там | Для чего брали |
|---|---|---|
| **QuestieDB для Forever** (локально, `tools/questie_db.py`) | квесты, NPC, координаты, цепочки | все ID и порядок шагов гида |
| [wago.tools](https://wago.tools/db2/TaxiPath?build=1.60.1.70707) — таблицы клиента 1.60.1.70707: [TaxiPath](https://wago.tools/db2/TaxiPath?build=1.60.1.70707), [TaxiNodes](https://wago.tools/db2/TaxiNodes?build=1.60.1.70707), [TaxiPathNode](https://wago.tools/db2/TaxiPathNode?build=1.60.1.70707), [SkillRaceClassInfo](https://wago.tools/db2/SkillRaceClassInfo?build=1.60.1.70707), [SpellLevels](https://wago.tools/db2/SpellLevels?build=1.60.1.70707), [SpellCooldowns](https://wago.tools/db2/SpellCooldowns?build=1.60.1.70707), [UiMapAssignment](https://wago.tools/db2/UiMapAssignment?build=1.60.1.70707) | файлы игры | полёты и цены, корабли и причалы, оружие друида, уровни заклинаний, откаты |
| [Wowhead Forever](https://www.wowhead.com/forever/zone=141/teldrassil): зоны [Тельдрассил](https://www.wowhead.com/forever/zone=141/teldrassil), [Темные берега](https://www.wowhead.com/forever/zone=148/darkshore), [Ясеневый лес](https://www.wowhead.com/forever/zone=331/ashenvale), [Болотина](https://www.wowhead.com/forever/zone=11/wetlands), [Сумеречный лес](https://www.wowhead.com/forever/zone=10/duskwood), [Лунная поляна](https://www.wowhead.com/forever/zone=493/moonglade); квесты [5925](https://www.wowhead.com/forever/quest=5925), [97894](https://www.wowhead.com/forever/quest=97894); подсказки заклинаний | база по данным беты | списки квестов (новые/изменённые), квестодатели, цепочки; проверка ID заклинаний для шагов обучения |

## 3. Фан-базы и трекеры Forever

| Источник | Что там | Для чего брали |
|---|---|---|
| [foreverchanges.pro](https://foreverchanges.pro/) — [изменения по классам](https://foreverchanges.pro/buffs-and-nerfs), [таланты друида](https://foreverchanges.pro/talents/druid), [книга заклинаний](https://foreverchanges.pro/spellbook/druid), [к 30 уровню](https://foreverchanges.pro/level-30), [спальник](https://foreverchanges.pro/cozy-sleeping-bag), [кошка](https://foreverchanges.pro/druid-cat-form) | сравнение с Classic по данным клиента | таланты после 30 октября, Свирепый укус на 24, опыт, спальник |
| [Bind on Forever](https://bindonforever.com/leveling/alliance) — зоны ([Тельдрассил](https://bindonforever.com/zones/teldrassil), [Темные берега](https://bindonforever.com/zones/darkshore), [Ясеневый лес](https://bindonforever.com/zones/ashenvale), [Когтистые горы](https://bindonforever.com/zones/stonetalon-mountains), [Болотина](https://bindonforever.com/zones/wetlands), [Лок Модан](https://bindonforever.com/zones/loch-modan), [Красногорье](https://bindonforever.com/zones/redridge-mountains), [Сумеречный лес](https://bindonforever.com/zones/duskwood), [Западный край](https://bindonforever.com/zones/westfall)), маршрут ночного эльфа по картам ([Тельдрассил](https://bindonforever.com/map/teldrassil?guide=nightelf-shadowglen), [Дарнас](https://bindonforever.com/map/darnassus?guide=nightelf-shadowglen), [Темные берега](https://bindonforever.com/map/darkshore?guide=nightelf-shadowglen), [Ясеневый лес](https://bindonforever.com/map/ashenvale?guide=nightelf-shadowglen), [Болотина](https://bindonforever.com/map/wetlands?guide=nightelf-shadowglen), [Стальгорн](https://bindonforever.com/map/ironforge?guide=nightelf-shadowglen), [Штормград](https://bindonforever.com/map/stormwind-city?guide=nightelf-shadowglen), [Сумеречный лес](https://bindonforever.com/map/duskwood?guide=nightelf-shadowglen)) | маршруты и новые квесты | порядок маршрута ночного эльфа |
| [seemeta: калькулятор талантов](https://seemeta.com/en/wow-forever/talent-calculator/druid) | таланты | уровни заклинаний |
| [kami-labs: книга заклинаний](https://kami-labs.fr/en/grimoire-wow-forever/), [дата запуска](https://kami-labs.fr/en/wow-classic/wow-forever-classic-plus-4-novembre/) | заклинания, новости | уровень Телепорта, дата запуска |

## 4. Гайды

| Источник | Для чего брали |
|---|---|
| Warcraft Tavern: [прокачка друида](https://www.warcrafttavern.com/forever/guides/druid-leveling/), [тренеры](https://www.warcrafttavern.com/forever/guides/class-trainers/), [учителя оружия](https://www.warcrafttavern.com/forever/guides/weapon-skill-trainers/), [наследие](https://www.warcrafttavern.com/forever/guides/legacy/), [верховая езда](https://www.warcrafttavern.com/forever/guides/riding/), [опыт](https://www.warcrafttavern.com/forever/guides/experience/), [лагерь](https://www.warcrafttavern.com/forever/guides/camping/), [сумки и банк](https://www.warcrafttavern.com/forever/news/changes-to-bags-banks-in-world-of-warcraft-forever/), [Excavation Site](https://www.warcrafttavern.com/forever/guides/excavation-site-wetlands/), [City of Dalaran](https://www.warcrafttavern.com/forever/guides/city-of-dalaran/), [опыт мобов в подземельях](https://www.warcrafttavern.com/forever/news/dungeon-mob-xp-drastically-lowered-in-wow-forever/), [нет поиска группы](https://www.warcrafttavern.com/forever/news/no-group-finder-or-summoning-stones-in-wow-forever/) | тренеры, оружие, маунт, лагерь, подземелья |
| Icy Veins: [облики друида](https://www.icy-veins.com/wow-forever/druid-shapeshift-forms), [Excavation Site](https://www.icy-veins.com/wow-forever/excavation-site-wetlands-quests), [Hall of Thanes](https://www.icy-veins.com/wow-forever/hall-of-thanes-quests), [новые подземелья](https://www.icy-veins.com/wow-forever/news/all-9-new-wow-forever-dungeons-previewed-how-to-access-level-ranges-locations-and-more/), [200+ новых квестов](https://www.icy-veins.com/wow-forever/news/over-200-new-quests-discovered-on-the-wow-forever-beta/), [корабли вместо бега через Болотину](https://www.icy-veins.com/wow/news/here-is-how-to-skip-the-infamous-wetlands-death-run-in-wow-forever/), [наследие](https://www.icy-veins.com/wow-forever/news/everything-on-the-wow-forever-legacy-system-account-wide-progression/), [скорость прокачки](https://www.icy-veins.com/wow-forever/news/blizzard-reveals-an-interesting-stat-about-wow-forevers-average-leveling-speed/) | облики, подземелья, корабли |
| Method: [друид](https://www.method.gg/wow-forever/wow-forever-druid-leveling-guide-and-talents), [транспорт](https://www.method.gg/wow-forever/all-travel-routes-in-wow-forever-boats-zeppelins), [маунт](https://www.method.gg/wow-forever/how-to-get-a-mount-in-wow-forever-cost-requirement-and-mount-options), [сумки](https://www.method.gg/wow-forever/best-early-bags-in-wow-forever-crafted-bags-quest-bags-vendor-bags-and-more) | корабли, маунт, сумки |
| warcraft.wiki.gg: [To Darnassus (Forever)](https://warcraft.wiki.gg/wiki/To_Darnassus_(Forever)), [Baron Marinous](https://warcraft.wiki.gg/wiki/Baron_Marinous), [Silva Fil'naveth](https://warcraft.wiki.gg/wiki/Silva_Fil'naveth), [точки полёта](https://warcraft.wiki.gg/wiki/Flight_path) | кошка, элита, полёты |
| [forg.gg: облики](https://forg.gg/en/forever/tips/druid-forms), [zockify: облики](https://www.zockify.com/forever/druid/forms/), [zockify: лагерь](https://www.zockify.com/forever/camping-system/) | цепочки обликов |
| conquestcapped: [транспорт](https://conquestcapped.com/guides/wow-forever/wow-forever-travel-routes/), [таланты друида](https://conquestcapped.com/guides/wow-forever/wow-forever-druid-talents/) | порядок кораблей, таланты |
| [mein-mmo: 46 советов](https://mein-mmo.de/en/wow-forever-beginners-guide-46-tips-to-make-your-start-noticeably-easier,1593013/2/) | журнал квестов, лагерь |

**Низкая надёжность** (только как подсказка): [urgametips: облики](https://urgametips.com/wow-forever/druid-guides/forms/), [expcarry: Trial of the Sea Lion](https://expcarry.com/wow-forever-trial-of-the-sea-lion), [leprestore: транспорт](https://leprestore.com/guides/world-of-warcraft-forever/wow-forever-travel-guide/), [games.gg: Темные берега](https://games.gg/world-of-warcraft/guides/wow-forever-darkshore-leveling-guide/).

## 5. Classic (не Forever — только как оценка)

| Источник | Для чего брали |
|---|---|
| What's Training: [цены друида](https://github.com/fusionpit/WhatsTraining/blob/master/Classes/Vanilla/Druid.lua), [оружие](https://github.com/fusionpit/WhatsTraining/blob/master/Classes/WeaponSkills.lua); версия для Forever — [CurseForge](https://www.curseforge.com/wow/addons/whats-training-forever) | цены тренеров (оценка), координаты учителя булав |
| [Warcraft Tavern: Classic маршрут Альянса](https://www.warcrafttavern.com/wow-classic/guides/alliance-leveling-guide/), [warcraft.wiki.gg: Тельдрассил](https://warcraft.wiki.gg/wiki/Teldrassil_questing_guide), [цепочка медведя](https://warcraft.wiki.gg/wiki/Bear_Form_quest_chain) | базовый порядок маршрута |
| Wowhead Classic: [Moonglade](https://www.wowhead.com/classic/quest=5921/moonglade), [Телепорт](https://www.wowhead.com/classic/spell=18960/teleport-moonglade) | Телепорт: Лунная поляна |
| [Форум EU: «30 уровень и только 16g»](https://eu.forums.blizzard.com/en/wow/t/level-30-and-only-16-gold/259743) | ориентир дохода к 30 |
| [Форум US: нормализация оружия ферала](https://us.forums.blizzard.com/en/wow/t/feral-druid-weapons-normalization/2367553) (мнения игроков Forever) | в облике кошки важен только DPS оружия |

## 6. Маршруты аддонов (сырые файлы маршрутов)

| Источник | Надёжность | Что там |
|---|---|---|
| [RestedXP: бесплатные маршруты Forever на GitHub](https://github.com/RestedXP/RXPGuides/tree/master/Guides/forever) — [ночной эльф 1–10](https://raw.githubusercontent.com/RestedXP/RXPGuides/master/Guides/forever/Alliance-1-10_NightElf.lua), [Альянс 11–20](https://raw.githubusercontent.com/RestedXP/RXPGuides/master/Guides/forever/Alliance-11-20.lua); [аддон на CurseForge](https://www.curseforge.com/wow/addons/restedxp-guide) (v4.11.29, 29 окт.); [статья об обновлении, 9 окт.](https://kami-labs.fr/en/wow-forever/mise-a-jour-restedxp-wow-forever/) | **высокая для 1–20**: проверено в бете | маршрут ночного эльфа по шагам с ID: крюк в Лок Модан на 15–16, Красногорье 19–20, кошка через Лунную поляну, поездка на 14 убрана («Removed in wowF»), полёт Sindrayl с Лунной поляны в Аубердин. 20/23–30 — платная часть, не публична |
| [Polestar на GitHub](https://github.com/fitzforge/polestar/tree/next/guides/forever/alliance) ([README](https://raw.githubusercontent.com/fitzforge/polestar/next/README.md)), [CurseForge](https://www.curseforge.com/wow/addons/polestar-guides) | средняя: собран симулятором по данным клиента и QuestieDB, в игре не проверялся | маршрут Тельдрассил → Западный край → Темные берега → Красногорье → Сумеречный лес → Ясеневый лес и Болотина; места трудных целей; шанс Stone of Relu 1,5% |
| [TUGs (Guidelime)](https://www.curseforge.com/wow/addons/guidelime_tugs), [Leveldon](https://www.curseforge.com/wow/addons/leveldon), [Wayfinder Forever](https://www.curseforge.com/wow/addons/wayfinder-forever), [4Ever Leveling](https://www.curseforge.com/wow/addons/foreverleveling) | разная, маршруты частично не проверены | порядок для ночного эльфа не опубликован |
| Помощники: [What's Training Forever](https://www.curseforge.com/wow/addons/whats-training-forever), [ForeverForge Training](https://www.curseforge.com/wow/addons/foreverforge-training) (цены у тренера), [TripView](https://www.curseforge.com/wow/addons/tripview), [ForeverTransport](https://www.curseforge.com/wow/addons/forevertransport) (корабли), [Forever Guide](https://www.curseforge.com/wow/addons/forever-guide) (база в игре) | инструменты | настоящие цены тренеров и таймеры кораблей видны только в игре |

## 7. Базы и калькуляторы по данным клиента

| Источник | Что там |
|---|---|
| [ForeverDB](https://foreverdb.net/class/Druid) ([тренеры](https://foreverdb.net/trainers)) | уровни заклинаний, Знамение ясности на 20, Волшебный огонь в облике, заклинания за квесты (данные на 31 окт.) |
| [WoW Forever Talents](https://wowforevertalents.com/druid/) ([изменения талантов](https://wowforevertalents.com/talent-changes/), [заклинания](https://wowforevertalents.com/abilities/druid/)) | дерево после 30 октября |
| Wowhead Forever, страницы квестов: [1033](https://www.wowhead.com/forever/quest=1033), [970](https://www.wowhead.com/forever/quest=970), [98072](https://www.wowhead.com/forever/quest=98072), [2098](https://www.wowhead.com/forever/quest=2098), [81730](https://www.wowhead.com/forever/quest=81730), [97914](https://www.wowhead.com/forever/quest=97914), [96634](https://www.wowhead.com/forever/quest=96634), [98046](https://www.wowhead.com/forever/quest=98046), [99053](https://www.wowhead.com/forever/quest=99053) | тексты квестов (комментарии при чтении не видны) |
| warcraft.wiki.gg: [Nightmare Incursions](https://warcraft.wiki.gg/wiki/Nightmare_Incursions), [Field Captain Palandar](https://warcraft.wiki.gg/wiki/Field_Captain_Palandar), [Glowing Soul Gem](https://warcraft.wiki.gg/wiki/Glowing_Soul_Gem), [Gyromast's Retrieval](https://warcraft.wiki.gg/wiki/Gyromast%27s_Retrieval), [Crimson Whelp](https://warcraft.wiki.gg/wiki/Crimson_Whelp) | откуда падают предметы для квестов; Duskwood Mission — это Season of Discovery |

**Устаревшие (дерево талантов до 30 октября — не использовать):** [guildorder.com](https://guildorder.com/games/wow_forever/talents/druid), [wow.gg: ферал](https://wow.gg/ru/guides/wow-forever-feral-druid-beta), страница прокачки друида на Warcraft Tavern, [Mobalytics: DoubleZug](https://mobalytics.gg/wow-forever/profile/doublezug/classes/feral-druid-leveling-guide-level-1-60).

## 8. Форумы Blizzard

Читались через `.json`-версию страниц. Синий пост — официальный ответ Blizzard, остальное — сообщения игроков. Всего около 70 тем; основные:

| Тема | Тип | О чём |
|---|---|---|
| [Заметки разработчиков беты](https://us.forums.blizzard.com/en/wow/t/2360696) (24 сен. — 27 окт.) | синий | исправления квестов (Body and Heart, How Big a Threat?, For Love Eternal, Raene's Cleansing, Twisted Hatred), Полосование на 20, облики |
| [Известные проблемы](https://us.forums.blizzard.com/en/wow/t/2352687) | синий | смена группы меняет слой |
| [Бета закрыта](https://us.forums.blizzard.com/en/wow/t/2390465) (23 окт.); [слои на кораблях и в городах](https://kami-labs.fr/en/wow-forever/wow-forever-layering-correctifs/) | синий / новость | что обещали исправить к запуску |
| Реликвия для облика кошки: [1](https://us.forums.blizzard.com/en/wow/t/2361281), [2](https://us.forums.blizzard.com/en/wow/t/2375782), [3](https://us.forums.blizzard.com/en/wow/t/2382975), [4](https://us.forums.blizzard.com/en/wow/t/2384231), [EU](https://eu.forums.blizzard.com/en/wow/t/635961) (25 сен. — 16 окт.) | игроки | очередь 2–3 часа, «There is no loot» при одновременных кликах |
| Навык Feral Combat: [1](https://us.forums.blizzard.com/en/wow/t/2389162), [промахи](https://us.forums.blizzard.com/en/wow/t/2356878), [бить мобов ниже уровнем](https://us.forums.blizzard.com/en/wow/t/2375453) | игроки | после получения медведя навык почти с нуля |
| Урон в облике: [медведь 2,5×, кошка 1× DPS оружия](https://us.forums.blizzard.com/en/wow/t/2380676), [медведем 10–20](https://us.forums.blizzard.com/en/wow/t/2367630) | игроки | от оружия зависит всё |
| Деньги: [9g к 20, 26g к 30](https://us.forums.blizzard.com/en/wow/t/2398327), [«денег всегда хватало»](https://us.forums.blizzard.com/en/wow/t/2397996), [золото за квесты «слишком большое»](https://eu.forums.blizzard.com/en/wow/t/638892) | игроки | денег больше, чем в Classic |
| Корабли и слои: [~10 минут ожидания на остановке](https://us.forums.blizzard.com/en/wow/t/2365523), [группа делится на корабле](https://eu.forums.blizzard.com/en/wow/t/634380), [приглашение в бою меняет слой](https://us.forums.blizzard.com/en/wow/t/2359785), [слой на корабле](https://us.forums.blizzard.com/en/wow/t/2364911) | игроки | не принимать приглашения в бою и в сопровождении |
| [Лунная поляна — спорная зона на PvP-серверах](https://us.forums.blizzard.com/en/wow/t/2354595) | игроки | могут убивать при телепорте |
| Узкие места: [сопровождение Remtravel](https://us.forums.blizzard.com/en/wow/t/2371700), [сопровождения по одному](https://us.forums.blizzard.com/en/wow/t/2374145), [добыча для Tower of Althalaxx](https://us.forums.blizzard.com/en/wow/t/2356672), [провалы в квестах эльфа 18–25](https://us.forums.blizzard.com/en/wow/t/2376192) | игроки | где маршрут буксует |
| [Свирепый укус ещё на 32 (29 окт.)](https://us.forums.blizzard.com/en/wow/t/2395814), [изменения ферала 30 окт.](https://us.forums.blizzard.com/en/wow/t/2396878) | игроки | изменения 30 октября |
| [Excavation Site: награды урезаны до зелёных](https://us.forums.blizzard.com/en/wow/t/2378440), [слишком сложное](https://us.forums.blizzard.com/en/wow/t/2369918) | игроки | подземелье 26–29 |

## 9. YouTube

Расшифровок нет, комментарии видны частично (около 20 лучших, без ответов).

| Видео | Дата | Что полезно |
|---|---|---|
| MMARKERS: [таланты после 30 окт.](https://www.youtube.com/watch?v=cj6ij0fTzR4), [ещё](https://www.youtube.com/watch?v=9-Maxg3SZZo), [закреплённый комментарий про камни для оружия](https://www.youtube.com/watch?v=fhGVx8Plwa4) | 29–31 окт. | Berserk убран, Primal Bite на 40; точильные камни с 16, Wizard Oil раньше |
| [Tactyks](https://www.youtube.com/watch?v=DbEq6GIOHbY) | 31 окт. | то же в комментариях |
| [I Cross Save: цепочка медведя](https://www.youtube.com/watch?v=LzgmlqscZJQ) | 5 окт. | главы подтверждают порядок квестов |
| [Hazpataz: Hall of Thanes](https://www.youtube.com/watch?v=_SPMGBs4Vcw) | 4 окт. | 5 квестов, скрытый на 5000 опыта |
| [Bulwark: Excavation Site](https://www.youtube.com/watch?v=KhARwalwIYo), [LostNiceland](https://www.youtube.com/watch?v=6WjUAo221S4) | 3 и 13 окт. | вход 47,56; дебаффы снимают жрец, паладин или шаман |
| [space goat: маршрут в описании](https://www.youtube.com/watch?v=jCQ2_WgXWcU), [Skidrow: ночной эльф-друид](https://www.youtube.com/watch?v=XLBWghr72-M) | 16 окт., 26 сен. | маршруты «через подземелья»: на 12–14 в Стальгорн |
| [Bornlesszero: Темные берега, 12 ур.](https://www.youtube.com/watch?v=CZC6S1AeZV0) | 1 нояб. | спидраннер в Темных берегах на 12 |
| [Tekn0de](https://www.youtube.com/watch?v=i_xkspMpv9g) + [письменный гайд](https://wowforeverguides.com/leveling/druid), [Kargoz](https://www.youtube.com/watch?v=81PPG39E2YE), [официальное видео о друиде](https://www.youtube.com/watch?v=8cYqQDGBLw0) | сен.–окт. | до 30 октября — таланты устарели |

У Payo, Pshero, Guzu, Savix, Esfand, Asmongold, Joana и других топ-стримеров видео про прокачку друида или маршруты в Forever не нашлось. Ссылок на Google Docs или Pastebin с маршрутами под видео нет.

## Недоступно при поиске

Reddit (инструмент чтения его не открывает), Mobalytics, MetaForge, dving.net, часть Icy Veins (ошибка 403), Twitch, расшифровки и полные комментарии YouTube, комментарии Wowhead.
