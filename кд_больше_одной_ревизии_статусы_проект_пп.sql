SELECT
  ko.prodcode,
  ko.unvcode,
  ko.revision,
  bo.revsign,
  ko.Sign AS koSign,
  ko.name AS koName,
  ko.recdate,
  bo.create_user,
  ul.fullName AS userName,
  lvl.name AS levelName
FROM
  -- подзапрос вычисляет количество ревизий на статусах
  -- "Проектирование" и "Подготовка производства"
  (
  SELECT
    ko.prodcode
  FROM
    konstrobj ko,
    businessobj_promotion bop,
    businessobj_states cs,
    businessobj_promotion_levels lvl
  WHERE
        bop.businessObj = ko.bocode
      AND
        bop.code = (
          SELECT
            Max(bop_.code)
          FROM
            businessobj_promotion bop_
          WHERE
              bop_.businessObj = bop.businessObj
        )
      AND
        cs.code = bop.current_state
      AND
        lvl.code = cs.promLevel
      AND
        lvl.name IN ('Проектирование', 'Подготовка производства')
  GROUP BY
    ko.prodCode
  HAVING
    Count(DISTINCT ko.unvcode) > 1

  ) ko_dub,
  -- конструкторские элементы
  konstrobj ko,
  -- бизнесс-объекты
  business_objects bo,
  -- пользователи
  user_list ul,
  -- уровни прожвижения объекта
  businessobj_promotion bop,
  -- статусы
  businessobj_states cs,
  -- справочник уровней продвижения
  businessobj_promotion_levels lvl
WHERE
    ko.prodCode = ko_dub.prodcode
  AND
    bo.code = ko.bocode
  AND
    ul.code = bo.create_user
  AND
    bop.businessObj = bo.code
  AND
    bop.code = (
      SELECT
        Max(bop_.code)
      FROM
        businessobj_promotion bop_
      WHERE
          bop_.businessObj = bop.businessObj
    )
  AND
    cs.code = bop.current_state
  AND
    lvl.code = cs.promLevel
  AND
    -- отбираются ревизии только на указанных ниже статусах
    lvl.name IN ('Проектирование', 'Подготовка производства')
ORDER BY
  -- сортировка по децимальному номеру, внутри - по номеру ревизии
  ko.Sign,
  ko.revision;