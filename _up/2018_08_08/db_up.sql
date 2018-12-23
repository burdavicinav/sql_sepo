-- 2018_07_22_v1 -> 2018_08_08_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_07_22_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

--DELETE FROM sepo_std_tp_params;

--DELETE FROM sepo_std_formulas;

DROP TABLE sepo_std_scheme_attrs_temp;

CREATE TABLE sepo_std_attrs (
  id_table NUMBER NOT NULL REFERENCES sepo_std_tables(id),
  id_attr NUMBER NOT NULL REFERENCES sepo_std_table_fields(id),
  omp_attr NUMBER NULL,
  omp_enum NUMBER NULL
);

CREATE OR REPLACE VIEW v_sepo_std_attr_values
AS
SELECT
  r.id AS id_record,
  f.id AS id_field,
  f.id_table,
  To_Number(regexp_replace(f.field, '\D', '')) AS f_order,
  f.field,
  f.f_longname,
  f.f_entermode,
  f.f_data,
  pf.field AS parent_field,
  c.field_value AS value_,
  pc.field_value AS parent_value,
  coalesce(c.field_value, pc.field_value) AS field_value
FROM
  sepo_std_records pr
  JOIN
  sepo_std_table_records r
  ON
      r.id_table = pr.id_table
  JOIN
  sepo_std_table_fields f
  ON
      f.id_table = r.id_table
  left JOIN
  sepo_std_table_rec_contents c
  ON
      c.id_record = r.id
    AND
      c.id_field = f.id
  left JOIN
  sepo_std_fields pf
  ON
      f.f_entermode = 'IEM_ASPARENT'
    AND
      f.f_longname = pf.f_longname
  left JOIN
  sepo_std_record_contents pc
  ON
      pc.id_record = pr.id
    AND
      pc.id_field = pf.id;

CREATE OR REPLACE VIEW v_sepo_std_attr_properties
AS
SELECT
  v.f_longname AS name,
  Min(
    CASE
      WHEN regexp_like(Trim(v.field_value), '^[-]?\d+$')
        OR v.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isnumber,
  Min(
    CASE
      WHEN regexp_like(Trim(v.field_value), '^[-]?\d+([\.,]\d+)?$')
        OR v.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isdouble,
  Min(
    CASE
      WHEN v.f_entermode = 'IEM_LIST' THEN 1
      ELSE 0
    END
  ) AS islist
FROM
  v_sepo_std_attr_values v
WHERE
    v.f_entermode IN (
      'IEM_SIMPLE',
      'IEM_ASPARENT',
      'IEM_LIST'
    )
GROUP BY
  v.f_longname;

CREATE OR REPLACE VIEW v_sepo_std_simple_attrs
AS
SELECT
  f.id AS id_attr,
  f.id_table AS id_table,
  f.field,
  f.f_datatype,
  f.f_entermode,
  f.f_data,
  a.name AS attr_name,
  CASE
    WHEN isnumber = 1 THEN 3
    WHEN isnumber = 0 AND isdouble = 1 THEN 2
    ELSE 1
  END omp_type
FROM
  v_sepo_std_attr_properties a,
  sepo_std_table_fields f
WHERE
    a.islist = 0
  AND
    f.f_longname = a.name
  AND
    f.f_entermode IN (
      'IEM_SIMPLE',
      'IEM_ASPARENT'
    );

UPDATE omp_sepo_properties SET property_value = '2018_08_08_v1' WHERE id = 2;