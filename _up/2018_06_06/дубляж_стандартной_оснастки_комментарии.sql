-- должен возвращать 10116 записей
-- каталоги 3726, 4208
-- если записей больше, проверить таблицы sepo_std_folder_codes
-- и fixture_types (особенно здесь, в системе нет проверки на уникальность)
-- на наличие дубляжа
SELECT
  i.lvl_type,
  i.id_record,
  i.reckey,
  i.tblkey,
  i.f_table,
  i.name,
  i.sign_vo,
  coalesce(c.key_, 0) AS lvlkey,
  t.code AS typecode,
  i.scheme_name,
  v.code AS scheme_code,
  i.gost
FROM
  v_sepo_std_import i,
  sepo_std_folder_codes c,
  fixture_types t,
  obj_enumerations e,
  obj_enumerations_values v
WHERE
    i.lvl_classify IN (3726, 4208)
  AND
    i.lvl_type = c.id_folder(+)
  AND
    c.name = t.name(+)
  AND
    e.name = '@Тип_оснастки'
  AND
    v.encode = e.code
  AND
    v.shortname = i.scheme_name
  ORDER BY
    reckey,
    tblkey;

-- каталог 3709
DECLARE

BEGIN
  DELETE FROM sepo_std_import_temp;

  INSERT INTO sepo_std_import_temp (
    id_record, id_parent_record, lvl_classify, lvl_type,
    f_level, reckey, tblkey, f_table, name, sign_vo, scheme_name, gost
  )
  SELECT
    *
  FROM
    v_sepo_std_import
  WHERE
      lvl_classify = 3709;
END;
/

-- 8094 записи
SELECT
  reckey,
  tblkey,
  f_table,
  name,
  sign_vo
FROM
  sepo_std_import_temp i
WHERE
  sign_vo IN
  (
    SELECT
      i_.sign_vo
    FROM
      sepo_std_import_temp i_
    WHERE
        i_.sign_vo = i.sign_vo
    GROUP BY
      i_.sign_vo
    HAVING
      Count(DISTINCT i_.id_record) = 1
  )
ORDER BY
  sign_vo;