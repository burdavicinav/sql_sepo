-- обновить представление
CREATE OR REPLACE VIEW v_sepo_std_field_values (
  id_parent_record,
  id_record,
  id_field,
  field,
  field_name,
  field_type,
  field_value,
  parent_field_value,
  imp_field_value,
  reckey,
  tblkey
) AS
SELECT
  pr.id AS id_parent_record,
  r.id AS id_record,
  f.id AS id_field,
  f.field,
  f.f_longname AS field_name,
  f.f_entermode AS field_type,
  c.field_value,
  pc.field_value AS parent_field_value,
  REPLACE (CASE
    WHEN f.f_entermode = 'IEM_ASPARENT' THEN
      coalesce(c.field_value, pc.field_value)
    ELSE
      c.field_value
  END, '~', ' ') AS imp_field_value,
  pr.f_key AS reckey,
  r.f_key AS tblkey
FROM
  sepo_std_table_fields f
  JOIN
  sepo_std_table_records r
  ON
      r.id_table = f.id_table
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = r.id_table
  left JOIN
  sepo_std_table_rec_contents c
  ON
      c.id_record = r.id
    AND
      c.id_field = f.id
  left JOIN
  sepo_std_fields pf
  ON
      pf.f_longname = f.f_longname
  left JOIN
  sepo_std_record_contents pc
  ON
      pc.id_record = pr.id
    AND
      pc.id_field = pf.id
  JOIN
  sepo_std_tables st
  ON
      st.id = r.id_table;


-- заполнение атрибута "СПРАВОЧНАЯ_ИНФО"
-- ВНИМАНИЕ! Нет ли триггеров на таблице obj_attr_values_32?
-- Если есть - выключить на время выполнения
DECLARE
  l_info_code NUMBER;
  l_attr_name VARCHAR2(100) := 'СПРАВОЧНАЯ_ИНФО';
  l_sqlup VARCHAR2(500);
BEGIN
  l_info_code := pkg_sepo_attr_operations.getcode(32, l_attr_name);

  l_sqlup := 'update obj_attr_values_32 set a_' || l_info_code ||
    '= :p1 where socode = :p2';

  FOR i IN (
    SELECT
      a.socode,
      fv.imp_field_value AS value_
    FROM
      v_sepo_std_field_values fv
      JOIN
      v_sepo_fixture_attrs a
      ON
          a.tblkey = fv.tblkey
        AND
          a.reckey = fv.reckey
    WHERE
        Upper(fv.field_name) = 'СПРАВОЧНАЯ ИНФОРМАЦИЯ'
      AND
        fv.imp_field_value IS NOT NULL
      AND
        a.objtype = 32

  ) LOOP
    EXECUTE IMMEDIATE l_sqlup USING i.value_, i.socode;

  END LOOP;

  COMMIT;

END;
/