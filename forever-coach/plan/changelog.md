# Что известно о Forever (журнал для плана)

Новые записи — сверху. Формат: дата — что узнали — ссылка.

## 2026-11-02 — разбор маршрута 1–30 и логистики (до запуска)

- Медведь у ночного эльфа — классическая цепочка (Heeding the Call → Moonglade → Great Bear Spirit → Back to Darnassus → Body and Heart, Lunaclaw у Аубердина). Ur'endra — цепочка расы Skyborne. Прежняя запись была ошибкой. — https://forg.gg/en/forever/tips/druid-forms , https://www.icy-veins.com/wow-forever/druid-shapeshift-forms
- Кошка на 20 — цепочка The Great Cat Spirit → To Darnassus (Дарнас → Лунная поляна → Дарнас). — https://warcraft.wiki.gg/wiki/To_Darnassus_(Forever)
- Урон автоатаки в облике медведя и кошки равен DPS надетого оружия, чары и проки работают. — https://worldofwarcraft.blizzard.com/en-us/news/24301515
- Тренер: Хватка природы на 10/18/28, Revive на 12, Знамение ясности и Полосование на 20, Tiger's Fury убран, Primal Bite — талант (не раньше 25). — та же новость и заметки разработчиков: https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-8/2360696
- Телепорт: Лунная поляна — 10 ур., бесплатно, без отката. Silva Fil'naveth: Лунная поляна → Рут'теран бесплатно; Рут'теран ↔ Аубердин бесплатно. Камень — откат 1 час. — таблицы клиента 1.60.1.70707: https://wago.tools/db2/TaxiPath?build=1.60.1.70707 , https://wago.tools/db2/SpellCooldowns?build=1.60.1.70707
- Корабли: Штормград ↔ Аубердин напрямую; петля Аубердин → Менетил → Южнобережье → Аубердин в одну сторону. — https://www.method.gg/wow-forever/all-travel-routes-in-wow-forever-boats-zeppelins , таблицы клиента (TaxiPathNode)
- Оружие: булавы — Buliwyf Stonehand (Стальгорн, 10s), древковое с 20 — Woo Ping (Штормград, 1g). — https://www.warcrafttavern.com/forever/guides/weapon-skill-trainers/
- Водный облик даёт Idol of Shifting Tides (−40 маны на превращение, данные беты). — https://urgametips.com/wow-forever/druid-guides/forms/
- Excavation Site: Wetlands — 26–31 (не 24–29); урезан только бонус опыта за квесты подземелий. — заметки разработчиков 1 октября (ссылка выше)
- Лагерь: костёр требует кулинарии, торговец и ремонт — роботы инженеров. — https://www.warcrafttavern.com/forever/guides/camping/
- Маунт с 40 за 100g (Method: с маунтом) или 100g + 20g (Warcraft Tavern). — https://www.method.gg/wow-forever/how-to-get-a-mount-in-wow-forever-cost-requirement-and-mount-options , https://www.warcrafttavern.com/forever/guides/riding/
- Наследие: первое очко класса на 25; Frequent Flier — полёты −50%. — https://www.warcrafttavern.com/forever/guides/legacy/
- Маршрут 1–30 и ID квестов: Wowhead Forever (зоны Teldrassil, Darkshore, Ashenvale, Wetlands, Duskwood), Bind on Forever (маршрут nightelf-shadowglen). ID и цепочки сверены с базой QuestieDB для Forever (`tools/questie_db.py`). — https://www.wowhead.com/forever/zone=141/teldrassil , https://bindonforever.com/map/teldrassil?guide=nightelf-shadowglen
- В базе Questie: The Principal Source доступна ночным эльфам; Trouble In Darkshore? открывает The Absent Minded Prospector; Ira's Dagger и Merrick's Bow начинаются с выпавших предметов; MacKreel's Moonshine выдаётся в Нагорье Арати.

## 2026-11-01 — исходные данные до запуска

- Запуск 4 ноября 2026, 15:00 PST (5 ноября 02:00 МСК). Бета была до 30 уровня. — https://kami-labs.fr/en/wow-classic/wow-forever-classic-plus-4-novembre/
- Темп прокачки как в Classic: до 20 уровня в среднем 20,5 ч против 20,4 ч. — https://www.icy-veins.com/wow-forever/news/blizzard-reveals-an-interesting-stat-about-wow-forevers-average-leveling-speed/
- Опыт за квесты подземелий урезан вдвое (1 окт.), за мобов в подземельях +20% (8 окт.). — https://www.warcrafttavern.com/forever/news/dungeon-mob-xp-drastically-lowered-in-wow-forever/
- Автоматического поиска группы и камней призыва нет. — https://www.warcrafttavern.com/forever/news/no-group-finder-or-summoning-stones-in-wow-forever/
- Облик медведя: цепочка у любого тренера друидов, убить Ur'endra. — https://www.icy-veins.com/wow-forever/druid-shapeshift-forms
- Таланты друида: Mangle → Primal Bite, Shifting Power, Знамение ясности и Хватка природы стали заклинаниями у тренера. — https://conquestcapped.com/guides/wow-forever/wow-forever-druid-talents/
- Корабли: порт Штормграда ↔ Аубердин, линия Менетил → Южнобережье → Аубердин. — https://www.icy-veins.com/wow/news/here-is-how-to-skip-the-infamous-wetlands-death-run-in-wow-forever/
- Темные берега: 6 новых квестов (Holy Diver, Baron Marinous, Swelling Forces, Unrequited Love, WANTED: Jai'vhanel, It's All Fun and Games Until...). — https://bindonforever.com/zones/darkshore
- Baron Marinous — элитный моб 21 ур. в руинах Матистры. — https://warcraft.wiki.gg/wiki/Baron_Marinous
- Новые подземелья: Hall of Thanes 13–18, Excavation Site: Wetlands 24–29, City of Dalaran 28–33, The Drowned City 35–40, Krol'dok Stronghold 40–45, Shaper's Terrace 58–60. — https://www.icy-veins.com/wow-forever/news/all-9-new-wow-forever-dungeons-previewed-how-to-access-level-ranges-locations-and-more/
- Excavation Site, квесты Альянса: Highland Hides (James Halloran, Менетил, от 24), Songblade Search (Dorin Songblade, Приозерье). — https://www.warcrafttavern.com/forever/guides/excavation-site-wetlands/
- City of Dalaran: цепочка An Alarming Request у Emissary Jacques в Южнобережье. — https://www.warcrafttavern.com/forever/guides/city-of-dalaran/
- Журнал квестов на 40 заданий; лагерь (camping) вместо костра. — https://mein-mmo.de/en/wow-forever-beginners-guide-46-tips-to-make-your-start-noticeably-easier,1593013/2/ , https://www.zockify.com/forever/camping-system/
- Наследие (Legacy): очки за испытания на весь аккаунт, до 16 на персонажа; перки Well Rested, Talented и др. — https://www.icy-veins.com/wow-forever/news/everything-on-the-wow-forever-legacy-system-account-wide-progression/
