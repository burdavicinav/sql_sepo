-- 1. меняется регистр у наименования стандартных и прочих изделий;
-- 2. замена " ОСТ1 " на "-ОСТ1 ".

-- список стандартных и прочих изделий с измененным наименованием
SELECT
  unvCode,
  itemType,
  Sign,
  name,
  pos,
  REPLACE(
    Upper(SubStr(name, 1, 1)) ||
    Lower(SubStr(name, 2, pos - 2)) ||
    SubStr(name, pos, Length(name) - pos + 1),
    ' ОСТ1 ',
    '-ОСТ1 '
    ) AS new_name
FROM
  (
  SELECT
    unvCode,
    itemType,
    Sign,
    Trim(name) AS name,
    InStr(Trim(name) || ' ', ' ') AS pos
  --  regexp_substr(LTrim(name) || ' ', '^[^ ]+ ')
  FROM
    konstrobj
  WHERE
      itemType IN (3, 4)
--    AND
--      InStr(Trim(name) || ' ', ' ') = Length(Trim(name) || ' ')
  );

-- для упрощения операции обновления
CREATE OR REPLACE VIEW view_sepo_konstrobj_update_name
AS
SELECT
  unvcode,
  REPLACE(
    Upper(SubStr(name, 1, 1)) ||
    Lower(SubStr(name, 2, pos - 2)) ||
    SubStr(name, pos, Length(name) - 1),
    ' ОСТ1 ',
    '-ОСТ1 '
    ) AS new_name
FROM
  (
  SELECT
    unvCode,
    itemType,
    Sign,
    Trim(name) AS name,
    InStr(Trim(name) || ' ', ' ') AS pos
  FROM
    konstrobj
  WHERE
      itemType IN (3,4)
  );

-- отключение триггеров
ALTER TRIGGER t_sepo_create_ko_name_row DISABLE;
ALTER TRIGGER taiud_konstrobj_sosign DISABLE;
ALTER TRIGGER taiur_konstrobj_sosign DISABLE;
ALTER TRIGGER taur_konstrobj_sosign DISABLE;
ALTER TRIGGER tbiu_konstrobj_sosign DISABLE;
ALTER TRIGGER tbu_sepo_konstrobj DISABLE;
ALTER TRIGGER tua_konstrobj DISABLE;
ALTER TRIGGER tua_standarts DISABLE;
ALTER TRIGGER tua_others DISABLE;
ALTER TRIGGER taiud_stockobj DISABLE;
ALTER TRIGGER taiur_stockobj DISABLE;
ALTER TRIGGER tbiu_stockobj DISABLE;
ALTER TRIGGER tub_stockobj DISABLE;

-- обновление данных

UPDATE konstrobj ko SET name = (
  SELECT
    new_name
  FROM
    view_sepo_konstrobj_update_name ko_
  WHERE
      ko_.unvcode = ko.unvcode
)
WHERE
    itemType IN (3,4);

UPDATE standarts s SET name = (
  SELECT
    new_name
  FROM
    view_sepo_konstrobj_update_name s_
  WHERE
      s_.unvcode = s.code
);

UPDATE OTHERS o SET name = (
  SELECT
    new_name
  FROM
    view_sepo_konstrobj_update_name o_
  WHERE
      o_.unvcode = o.code
);

UPDATE stockobj s SET name = (
  SELECT
    new_name
  FROM
    view_sepo_konstrobj_update_name s_
  WHERE
      s_.unvcode = s.unvcode
)
WHERE
    baseType = 0
  AND
    SUBTYPE IN (3,4);

UPDATE stockobj s SET description = Sign || ' ' || name
WHERE
    baseType = 0
  AND
    SUBTYPE IN (3,4);

-- включение триггеров

ALTER TRIGGER t_sepo_create_ko_name_row ENABLE;
ALTER TRIGGER taiud_konstrobj_sosign ENABLE;
ALTER TRIGGER taiur_konstrobj_sosign ENABLE;
ALTER TRIGGER taur_konstrobj_sosign ENABLE;
ALTER TRIGGER tbiu_konstrobj_sosign ENABLE;
ALTER TRIGGER tbu_sepo_konstrobj ENABLE;
ALTER TRIGGER tua_konstrobj ENABLE;
ALTER TRIGGER tua_standarts ENABLE;
ALTER TRIGGER tua_others ENABLE;
ALTER TRIGGER taiud_stockobj ENABLE;
ALTER TRIGGER taiur_stockobj ENABLE;
ALTER TRIGGER tbiu_stockobj ENABLE;
ALTER TRIGGER tub_stockobj ENABLE;