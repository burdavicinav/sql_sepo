-- всего сборочных материалов в Ѕƒ
SELECT Count(*) FROM konstrobj
WHERE
    itemType = 5;

-- список сборочных материалов, вход€щих в две и более спецификации
SELECT
  ko.prodCode,
  ko.Sign,
  Count(DISTINCT spc.prodCode)
FROM
  konstrobj ko,
  specifications sp,
  konstrobj spc
WHERE
    ko.itemType = 5
  AND
    sp.code = ko.unvCode
  AND
    spc.unvCode = sp.spcCode
GROUP BY
  ko.prodCode,
  ko.Sign
HAVING
  Count(DISTINCT spc.prodCode) > 1
ORDER BY
  ko.Sign;

-- алгоритм
-- отбирает материалы, вход€щие только в одну спецификацию (без учета ревизий)
-- новое обозначение материала формируетс€ как:
-- децимальный номер сборки + "-" + номер позиции (все, что стоит между
-- '-' и 'ћ'(при наличии) в текущем обозначении материала) + "ћ"
CREATE OR REPLACE VIEW view_sepo_spc_materials_update
AS
SELECT
  ko.unvCode AS mat_code,
  ko.prodCode AS mat_prodcode,
  ko.Sign AS mat_sign,
  ko.revision AS mat_revision,
  spc.unvCode AS spec_code,
  spc.prodCode AS spec_prodcode,
  spc.Sign AS spec_sign,
  spc.revision AS spec_revision,
  sp.position AS position_spec,
  regexp_replace(ko.Sign, '-\w{1,}ћ?$', '') AS spec_section,
  regexp_substr(ko.Sign, '-\w{1,}ћ?$') AS position_section,
  spc.Sign ||
  '-' ||
  regexp_replace(regexp_substr(ko.Sign, '-\w{1,}ћ?$'), '-|ћ', '') ||
  --regexp_replace(regexp_substr(ko.Sign, '-\d{1,}ћ?$'), '\D', '') ||
  'ћ'
    AS new_mat_sign
FROM
  (
  SELECT
    ko.prodCode,
    Count(DISTINCT spc.prodCode)
  FROM
    konstrobj ko,
    specifications sp,
    konstrobj spc
  WHERE
      ko.itemType = 5
    AND
      sp.code = ko.unvCode
    AND
      spc.unvCode = sp.spcCode
  GROUP BY
    ko.prodCode
  HAVING
    Count(DISTINCT spc.prodCode) = 1
  ) alg,
  konstrobj ko,
  specifications sp,
  konstrobj spc
WHERE
    ko.prodCode = alg.prodCode
  AND
    sp.code = ko.unvCode
  AND
    spc.unvCode = sp.spcCode
ORDER BY
  ko.Sign,
  spc.Sign;

-- материалы, отработанные алгоритмом
SELECT * FROM view_sepo_spc_materials_update up;

-- список материалов, текущие децимальные номера которых
-- совпадают с децимальным номером сборки
SELECT
  up.*,
  regexp_replace(up.spec_sign, '\W', ''),
  regexp_replace(up.spec_section, '\W', '')
FROM
  view_sepo_spc_materials_update up
WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '');

-- список материалов, текущие децимальные номера которых
-- Ќ≈ совпадают с децимальным номером сборки
SELECT
  up.*,
  regexp_replace(up.spec_sign, '\W', ''),
  regexp_replace(up.spec_section, '\W', '')
FROM
  view_sepo_spc_materials_update up
WHERE
    regexp_replace(up.spec_sign, '\W', '') !=
      regexp_replace(up.spec_section, '\W', '');

-- новые децимальные номера материалов совпадают
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    new_mat_sign
  FROM
    view_sepo_spc_materials_update
  GROUP BY
    new_mat_sign
  HAVING
    Count(DISTINCT mat_prodcode) > 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- тоже, что и предыдущий запрос, только поиск осуществл€етс€ среди
-- материалов, подлежащих обновлению
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) > 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- в итоге список материалов дл€ обновлени€
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) = 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
--  AND
--    a.mat_sign = a.new_mat_sign
  AND
    regexp_replace(a.spec_sign, '\W', '') =
      regexp_replace(a.spec_section, '\W', '')
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- мысль об атрибуте chndn
SELECT * FROM obj_attributes
WHERE
    objType = 5
  AND
    shortName = 'CHNDN';

-- 7458
SELECT
  ko.unvcode,
  ko.prodcode,
  ko.Sign,
  attr_5.A_7458 -- код из запроса выше
FROM
  konstrobj ko,
  business_objects bo,
  obj_attr_values_5 attr_5
WHERE
    ko.itemType = 5
  AND
    ko.unvCode = bo.doccode
  AND
    ko.prodcode = bo.prodcode
  AND
    attr_5.socode = bo.code
  AND
    attr_5.A_7458 IS NULL;

-- есть пустые значени€...


-- попробуй через сохранение данных в таблице
-- скорость запроса ниже увеличиваетс€ в 4 раза
CREATE TABLE sepo_spc_materials_update
AS
SELECT * FROM view_sepo_spc_materials_update;

-- проверка на существование материалов, децимальные номера которых
-- совпадают с новым сформированным кодом материала

-- выполн€етс€ теперь за 0.5 секунды
SELECT
  a.*
FROM
  sepo_spc_materials_update a,
--  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    sepo_spc_materials_update up
--    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) = 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
--  AND
--    a.mat_sign = a.new_mat_sign
  AND
    regexp_replace(a.spec_sign, '\W', '') =
      regexp_replace(a.spec_section, '\W', '')
  AND
    EXISTS
    (
      SELECT 1 FROM bo_production bo
      WHERE
          bo.Sign = a.new_mat_sign
        AND
          bo.code != a.mat_prodcode
        AND
          bo.TYPE = 5
    )
ORDER BY
  a.new_mat_sign,
  a.mat_sign


-- если результат запроса непустой, то плохо.
-- уже есть материал с таким обозначением в базе
-- ищи их в следующем запросе
SELECT * FROM bo_production
WHERE
    TYPE = 5
  AND
    Sign = <new_mat_sign из предыдущего запроса>;