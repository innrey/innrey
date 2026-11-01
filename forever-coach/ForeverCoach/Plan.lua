-- ForeverCoach: план прокачки.
-- Этот файл переписывает Claude (команды /next и /update-plan в Claude Code).
-- Это обычная Lua-таблица: после правки в игре нужен /reload (или /fc sync).
-- Если файл сломан, аддон работает без плана и пишет об этом в своём окне.

ForeverCoachPlan = {
  updated = "2026-11-01",
  source = "Стартовый план: ночной эльф, друид, соло. Уровни 30-60 в бете не проверялись.",

  -- Текущие шаги от Claude после последней синхронизации.
  -- Пример: now = { char = "Имя", level = 12, at = "05.11 03:10", steps = { "...", "..." } },
  now = nil,

  -- Метки квестов по ID (работают в любой локализации клиента).
  -- Claude заполняет их по ID из снимка состояния.
  skip = {},      -- [questID] = "почему пропустить"
  optional = {},  -- [questID] = "когда имеет смысл"
  key = {},       -- [questID] = "почему важно"

  -- Запасные метки по английским названиям (английский клиент).
  -- На русском клиенте Claude после первой синхронизации переносит их в skip/optional/key по ID.
  skipTitle = {
    ["Twisted Hatred"] = "долго за мало опыта",
    ["The Relics of Wakening"] = "долго за мало опыта",
    ["Baron Marinous"] = "элитный моб 21 ур., не соло на 15-20",
    ["Trial of the Sea Lion"] = "Водный облик для прокачки не нужен (30-40 минут)",
    ["Underground Map"] = "Hall of Thanes: для эльфа крюк до Стальгорна",
    ["The Legend of Stalvan"] = "беготня по всему миру",
    ["Mor'Ladim"] = "элитный моб",
  },
  optionalTitle = {
    ["Lady Sathrah"] = "только если наткнулся на неё",
    ["Tharnariun's Hope"] = "только если в облике медведя идёт легко",
    ["Morbent Fel"] = "не раньше 32 уровня",
  },
  keyTitle = {
    ["Flight to Auberdine"] = "бесплатный полёт на Темные берега",
    ["The Absent Minded Prospector"] = "много опыта за сопровождение",
    ["Highland Hides"] = "квест подземелья Excavation Site (от 24 ур.)",
  },

  -- Сообщения в чат при получении уровня.
  milestones = {
    [10] = "Квест на облик медведя у тренера друидов (убить Ur'endra). Выучи Телепортацию: Лунная поляна.",
    [16] = "Водный облик - пропусти, для прокачки не нужен.",
    [20] = "Телепорт на Лунную поляну -> тренер: облик кошки и Знамение ясности -> камнем обратно.",
    [24] = "Можно брать Highland Hides в Менетиле (подземелье Excavation Site).",
    [30] = "Походный облик (+40% скорости) - сразу к тренеру через телепорт.",
  },

  -- Пороги предупреждений.
  alerts = {
    bagFreeMin = 3,        -- предупреждать, когда свободных слотов столько или меньше
    durabilityMin = 0.3,   -- предупреждать, когда прочность ниже 30%
  },

  -- Базовый маршрут: показывается, когда от Claude нет свежих шагов.
  -- min включительно, max не включительно.
  route = {
    { min = 1, max = 6, zone = "Тенистая долина",
      text = "Balance of Nature -> у дерева взять всё -> Tarindrella (мох с грелей) -> Iverron -> пещера Shadowthread за один заход (яд, ихор, Webwood Egg, Githyiss) -> сдать -> Crown of the Earth -> Dolanaar Delivery." },
    { min = 6, max = 10, zone = "Доланаар",
      text = "Камень в таверну. Zenn's Bidding, Denalan (семена и ростки), Webwood Corruption, Emerald Dreamcatcher и Ferocitas, Road to Darnassus, Crown of the Earth ч.2. Пропусти: Twisted Hatred, Relics of Wakening." },
    { min = 10, max = 12, zone = "Тельдрассил: медведь и вылет",
      text = "Сразу квест на медведя (Ur'endra). Дарнас: Rellian -> Tumors -> Return to Denalan. Выучи Телепорт: Лунная поляна. Добей Crown of the Earth. Рут'теран: Flight to Auberdine на 11-12." },
    { min = 12, max = 15, zone = "Темные берега, север",
      text = "Камень в Аубердин. Washed Ashore, Buzzbox 827, Bashal'Aran, Plagued Lands, Easy Strider Living, How Big a Threat?" },
    { min = 15, max = 17, zone = "Темные берега, дальний север",
      text = "Buzzbox 411/323, Cleansing of the Infected, Mathystra Relics, Tower of Althalaxx и новые квесты по пути. Пропусти: Baron Marinous, Водный облик." },
    { min = 17, max = 20, zone = "Темные берега, юг",
      text = "Ameth'Aran: Tools of the Highborne, Fall of Ameth'Aran, For Love Eternal. Absent Minded Prospector, Onu и Master's Glaive, Escape Through Force, WANTED: Murkdeep! С юга пешком в Ясеневый лес." },
    { min = 20, max = 24, zone = "Ясеневый лес",
      text = "20: телепорт -> тренер (кошка, Знамение ясности) -> камнем обратно. Пост Маэстры: Althalaxx, Bathran's Hair, Zoram Strand. Астранаар: Raene's Cleansing, Ruins of Stardust." },
    { min = 24, max = 27, zone = "Болотина",
      text = "Корабль Аубердин -> Менетил. Highland Hides (James Halloran) - квест Excavation Site. Есть группа на доске - один заход со всеми квестами." },
    { min = 27, max = 28, zone = "Красногорье",
      text = "Полёт в Стальгорн -> трамвай -> Штормград -> Приозерье." },
    { min = 28, max = 30, zone = "Сумеречный лес",
      text = "Темнолесье. Пропусти: Legend of Stalvan, Mor'Ladim, Morbent Fel (рано). На 30 - Походный облик." },
    { min = 30, max = 35, zone = "Хилсбрад и Альтерак (черновик)",
      text = "Южнобережье: City of Dalaran (28-33, цепочка у Emissary Jacques). Затем Альтеракские горы." },
    { min = 35, max = 40, zone = "Тернистая долина (черновик)",
      text = "Тернистая долина и подземелье The Drowned City (35-40). Новая зона Riverglades (35-45)." },
    { min = 40, max = 45, zone = "40-45 (черновик)",
      text = "Riverglades, Krol'dok Stronghold (40-45), Пустоши, Пылевые топи." },
    { min = 45, max = 50, zone = "45-50 (черновик)",
      text = "Shen'dralas (данные по уровням расходятся), Фералас, Танарис, Внутренние земли." },
    { min = 50, max = 60, zone = "50-60 (черновик)",
      text = "Ун'Горо (Shaper's Terrace 58-60), Оскверненный лес, Зимние Ключи, Чумные земли." },
    { min = 60, max = 61, zone = "60",
      text = "Готово. Дальше Хиджал и рейды." },
  },
}
