-- представление для атрибутов оснастки
DECLARE
  l_table_31 NUMBER;
  l_tblkey_31 NUMBER;
  l_reckey_31 NUMBER;
  l_art_31 NUMBER;
  l_vo_31 NUMBER;
  l_table_32 NUMBER;
  l_tblkey_32 NUMBER;
  l_reckey_32 NUMBER;
  l_art_32 NUMBER;
  l_vo_32 NUMBER;
  l_table_33 NUMBER;
  l_tblkey_33 NUMBER;
  l_reckey_33 NUMBER;
  l_vo_33 NUMBER;
  l_sql VARCHAR2(2000);
BEGIN
  l_table_31 := pkg_sepo_attr_operations.getcode(31, 'Table');
  l_tblkey_31 := pkg_sepo_attr_operations.getcode(31, 'TBLKey');
  l_reckey_31 := pkg_sepo_attr_operations.getcode(31, 'RecKey');
  l_vo_31 := pkg_sepo_attr_operations.getcode(31, 'О_ВО');
  l_art_31 := pkg_sepo_attr_operations.getcode(31, 'ART_ID');

  l_table_32 := pkg_sepo_attr_operations.getcode(32, 'Table');
  l_tblkey_32 := pkg_sepo_attr_operations.getcode(32, 'TBLKey');
  l_reckey_32 := pkg_sepo_attr_operations.getcode(32, 'RecKey');
  l_vo_32 := pkg_sepo_attr_operations.getcode(32, 'О_ВО');
  l_art_32 := pkg_sepo_attr_operations.getcode(32, 'ART_ID');

  l_table_33 := pkg_sepo_attr_operations.getcode(33, 'Table');
  l_tblkey_33 := pkg_sepo_attr_operations.getcode(33, 'TBLKey');
  l_reckey_33 := pkg_sepo_attr_operations.getcode(33, 'RecKey');
  l_vo_33 := pkg_sepo_attr_operations.getcode(33, 'О_ВО');


  l_sql :=
  'create or replace view v_sepo_fixture_attrs as ' ||
  'select socode, objtype, table_, tblkey, reckey, o_vo, art_id ' ||
  'from (select ' ||
    'socode,' ||
    'a_' || l_table_31 || ' as table_,' ||
    'a_' || l_tblkey_31 || ' as tblkey,' ||
    'a_' || l_reckey_31 || ' as reckey,' ||
    'a_' || l_vo_31 || ' AS o_vo,' ||
    'a_' || l_art_31 || ' as art_id ' ||
  'from ' ||
    'obj_attr_values_31 ' ||
  'union all ' ||
  'select ' ||
    'socode,' ||
    'a_' || l_table_32 || ' as table_,' ||
    'a_' || l_tblkey_32 || ' as tblkey,' ||
    'a_' || l_reckey_32 || ' as reckey,' ||
    'a_' || l_vo_32 || ' AS o_vo,' ||
    'a_' || l_art_32 || ' as art_id ' ||
  'from ' ||
    'obj_attr_values_32 ' ||
  'union all ' ||
  'select ' ||
    'socode,' ||
    'a_' || l_table_33 || ' as table_,' ||
    'a_' || l_tblkey_33 || ' as tblkey,' ||
    'a_' || l_reckey_33 || ' as reckey,' ||
    'a_' || l_vo_33 || ' AS o_vo,' ||
    'null as art_id ' ||
  'from ' ||
    'obj_attr_values_33),' ||
  'omp_objects ' ||
  'where code = socode';

  Dbms_Output.put_line(l_sql);
  EXECUTE IMMEDIATE l_sql;

END;
/

CREATE OR REPLACE VIEW v_sepo_technological_par_steps
AS
WITH srec (
  stepcode,
  groupcode,
  parent,
  steptext
)
AS
(
  SELECT
    s.code,
    s.groupcode,
    s.parent_step,
    s.name
  FROM
    technological_steps s
  UNION ALL
  SELECT
    srec.stepcode,
    s.groupcode,
    s.parent_step,
    s.name || ' ' || srec.steptext
  FROM
    technological_steps s,
    srec
  WHERE
      s.code = srec.parent
)
SELECT
  stepcode,
  groupcode,
  steptext
FROM
  srec
WHERE
    parent IS NULL;

CREATE OR REPLACE VIEW v_sepo_technological_steps
AS
WITH cl (
  stepcode,
  groupcode,
  steptext
)
AS
(
  SELECT
    s.stepcode,
    s.groupcode,
    s.steptext
  FROM
    v_sepo_technological_par_steps s
  UNION ALL
  SELECT
    cl.stepcode,
    upper_group,
    g.grname || ' ' || cl.steptext
  FROM
    groups_in_classify g,
    cl
  WHERE
      cl.groupcode = g.code
)
SELECT
  cl.stepcode,
  cl.steptext
FROM
  cl
WHERE
    cl.groupcode IS NULL;

CREATE OR REPLACE VIEW v_sepo_import_tech_steps
AS
WITH sp (
  f_key,
  f_level,
  f_owner,
  steptext
)
AS
(
  SELECT
    f_key,
    f_level,
    f_owner,
    f_name
  FROM
    sepo_tech_steps
  WHERE
      f_name != 'ИЗ КЛАССИФИКАТОРА'
  UNION ALL
  SELECT
    sp.f_key,
    sp.f_level,
    s.f_owner,
    s.f_name || ' ' || sp.steptext
  FROM
    sepo_tech_steps s,
    sp
  WHERE
      s.f_level = sp.f_owner
    AND
      s.f_name != 'ИЗ КЛАССИФИКАТОРА'
)
SELECT
  *
FROM
  sp
WHERE
    f_owner = 0;

CREATE OR REPLACE VIEW v_sepo_tp_steps
AS
SELECT
  s.id AS id_step,
  s.operkey,
  s.key_ AS perehkey,
  f1.f_value AS stepname,
  f2.f_value AS stepnumber,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  omp.stepcode AS ompcode
FROM
  sepo_tp_steps s
  left JOIN
  sepo_tp_step_fields f1
  ON
      f1.id_step = s.id
    AND
      f1.field_name = 'Тепр'
  left JOIN
  sepo_tp_step_fields f2
  ON
      f2.id_step = s.id
    AND
      f2.field_name = 'Nпер'
  left JOIN
  sepo_tp_step_comments c
  ON
      c.id_step = s.id
  left JOIN
  (
  SELECT
    sp.f_level,
    omp.stepcode,
    sp.steptext
  FROM
    v_sepo_import_tech_steps sp,
    v_sepo_technological_steps omp
  WHERE
      sp.steptext = omp.steptext
  ) omp
  ON
      s.reckey = omp.f_level;

CREATE GLOBAL TEMPORARY TABLE sepo_tp_steps_temp (
  id_step NUMBER,
  operkey NUMBER,
  perehkey NUMBER,
  stepname VARCHAR2(2000),
  stepnumber NUMBER,
  remark CLOB,
  ompcode NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE VIEW v_sepo_std_formul_on_fields
AS
SELECT
  id_record,
  id_tool,
  id_field,
  field_value
FROM
  sepo_std_formulas
WHERE
    id_tool IS NOT NULL
UNION ALL
SELECT
  f1.id_record,
  f2.id_tool,
  f1.id_field,
  f1.field_value
FROM
  sepo_std_formulas f1
  left JOIN
  sepo_std_formulas f2
  ON
      f1.id_record = f2.id_record
    AND
      f2.id_tool IS NOT NULL
WHERE
    f1.id_tool IS NULL
GROUP BY
  f1.id_record,
  f2.id_tool,
  f1.id_field,
  f1.field_value;

CREATE OR REPLACE VIEW v_sepo_std_dop_data
AS
SELECT
  g.id_record,
  n.field_value AS name,
  v.field_value AS sign_vo,
  n2.field_value AS name_vo
FROM
  (
  SELECT
    fr.id_record,
    coalesce(fr.id_tool, -1) AS id_tool
  FROM
    v_sepo_std_formul_on_fields fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Полное наименование',
        'Обозначение для ВО',
        'Наименование для ВО'
      )
  GROUP BY
    fr.id_record,
    fr.id_tool
  ) g
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    v_sepo_std_formul_on_fields fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Полное наименование'
      )
  ) n
  ON
      g.id_record = n.id_record
    AND
      g.id_tool = n.id_tool
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Обозначение для ВО'
      )
  ) v
  ON
      g.id_record = v.id_record
    AND
      g.id_tool = v.id_tool
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    v_sepo_std_formul_on_fields fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Наименование для ВО'
      )
  ) n2
  ON
      g.id_record = n2.id_record
    AND
      g.id_tool = n2.id_tool
GROUP BY
  g.id_record,
  n.field_value,
  v.field_value,
  n2.field_value;

CREATE OR REPLACE VIEW v_sepo_std_formula_names
AS
SELECT
  fm.id,
  fm.id_record,
  r.f_key AS tblkey,
  pr.f_key AS reckey,
  fm.id_tool,
  f.f_longname,
  fm.field_value AS name
FROM
  sepo_std_formulas fm,
  sepo_std_table_fields f,
  sepo_std_table_records r,
  sepo_std_records pr
WHERE
    f.id = fm.id_field
  AND
    r.id = fm.id_record
  AND
    pr.id_table = r.id_table;

CREATE OR REPLACE VIEW v_sepo_tp_tools
AS
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.date_,
  t.kind,
  t.count_,
  t.reckey AS catalog,
  f1.f_value AS reckey,
  t.tblkey,
  f2.f_value AS o_vo,
  CASE
    WHEN NOT regexp_like(f3.f_value, '^\d+([,\.]\d+)?$') THEN 0
    ELSE To_Number(REPLACE(f3.f_value, ',', '.')) / 1000
  END AS norm
FROM
  sepo_tp_tools t
  left JOIN
  sepo_tp_tool_fields f1
  ON
      f1.id_tool = t.id
    AND
      f1.field_name = 'OsRc'
  left JOIN
  sepo_tp_tool_fields f2
  ON
      f2.id_tool = t.id
    AND
      f2.field_name = 'О_ВО'
  left JOIN
  sepo_tp_tool_fields f3
  ON
      f3.id_tool = t.id
    AND
      f3.field_name = 'НРАС';

CREATE OR REPLACE VIEW v_sepo_tp_fixture_3709
AS
SELECT
  id,
  id_tp,
  operkey,
  perehkey,
  key_,
  order_,
  catalog,
  tp_reckey,
  tp_tblkey,
  tp_vo,
  norm,
  socode,
  objtype,
  art_id,
  table_,
  tblkey,
  reckey,
  o_vo,
  unvcode,
  Sign AS ksign,
  name AS kname
FROM
  (
  SELECT
    t.id,
    t.id_tp,
    t.operkey,
    t.perehkey,
    t.key_,
    t.order_,
    t.catalog,
    t.reckey AS tp_reckey,
    t.tblkey AS tp_tblkey,
    t.o_vo AS tp_vo,
    t.norm AS norm,
    a.socode,
    a.objtype,
    a.art_id,
    a.table_,
    a.tblkey,
    a.reckey,
    a.o_vo,
    k.unvcode,
    k.Sign,
    k.name,
    Row_Number() OVER (
      PARTITION BY t.id
      ORDER BY
        CASE
          WHEN k.Sign NOT LIKE '%СБ' THEN 0
          ELSE 1
        END,
        CASE
          WHEN a.o_vo = k.Sign THEN 0
          ELSE 1
        END,
        a.objtype
      ) AS num
  FROM
    v_sepo_tp_tools t
    JOIN
    v_sepo_fixture_attrs a
    ON
        a.o_vo = t.o_vo
      AND
        a.objtype IN (31, 32)
    JOIN
    konstrobj k
    ON
        k.bocode = a.socode
  WHERE
      t.catalog = 3709
  )
WHERE
    num = 1;

CREATE OR REPLACE VIEW v_sepo_tp_fixture_old
AS
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.catalog,
  t.reckey AS tp_reckey,
  t.tblkey AS tp_tblkey,
  t.norm,
  t.o_vo AS tp_vo,
  o.socode,
  o.objtype,
  o.art_id,
  o.table_,
  o.tblkey,
  o.reckey,
  o.o_vo,
  o.unvcode,
  o.ksign,
  o.kname
FROM
  v_sepo_tp_tools t
  JOIN
  (
    SELECT
      a.socode,
      a.objtype,
      a.table_,
      a.tblkey,
      a.reckey,
      a.o_vo,
      a.art_id,
      k.unvcode,
      k.Sign AS ksign,
      k.name AS kname,
      n.id_tool,
      n.name
    FROM
      v_sepo_fixture_attrs a
      JOIN
      konstrobj k
      ON
          k.bocode = a.socode
      left JOIN
      v_sepo_std_formula_names n
      ON
          n.reckey = a.reckey
        AND
          n.tblkey = a.tblkey
        AND
          n.name = k.name
        AND
          n.f_longname = 'Наименование для ВО'
  ) o
  ON
      t.reckey = o.reckey
    AND
      t.tblkey = o.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog IN (4046, 4143, 4208);

CREATE OR REPLACE VIEW v_sepo_tp_fixture_std
AS
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.catalog,
  t.reckey AS tp_reckey,
  t.tblkey AS tp_tblkey,
  t.o_vo AS tp_vo,
  t.norm,
  o.socode,
  o.objtype,
  o.art_id,
  o.table_,
  o.tblkey,
  o.reckey,
  o.o_vo,
  o.unvcode,
  o.ksign,
  o.kname
FROM
  v_sepo_tp_tools t
  JOIN
  (
    SELECT
      a.socode,
      a.objtype,
      a.table_,
      a.tblkey,
      a.reckey,
      a.o_vo,
      a.art_id,
      k.unvcode,
      k.Sign AS ksign,
      k.name AS kname,
      n.id_tool,
      n.name
    FROM
      v_sepo_fixture_attrs a
      JOIN
      konstrobj k
      ON
          k.bocode = a.socode
      left JOIN
      v_sepo_std_formula_names n
      ON
          n.reckey = a.reckey
        AND
          n.tblkey = a.tblkey
        AND
          n.name = k.name
        AND
          n.f_longname = 'Полное наименование'
  ) o
  ON
      t.reckey = o.reckey
    AND
      t.tblkey = o.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog NOT IN (3709, 4046, 4143, 4208);

CREATE GLOBAL TEMPORARY TABLE sepo_tp_tools_temp (
  id_tool NUMBER,
  tool_code NUMBER,
  operkey NUMBER,
  perehkey NUMBER,
  count_ NUMBER,
  norm NUMBER,
  ordernum NUMBER
) ON COMMIT PRESERVE ROWS;

UPDATE omp_sepo_properties
SET
  property_value = '1.0.0.201'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2018_07_22_v1'
WHERE
    id = 2;