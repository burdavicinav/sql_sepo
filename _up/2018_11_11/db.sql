-- 2018_11_10_v1 -> 2018_11_11_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_11_10_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

CREATE SEQUENCE sq_sepo_std_tp_params;

CREATE OR REPLACE TRIGGER tbi_sepo_std_tp_params
BEFORE INSERT ON sepo_std_tp_params
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_tp_params.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_std_attr_values (
  id_record,
  id_field,
  id_table,
  f_order,
  field,
  f_longname,
  f_entermode,
  f_data,
  parent_field,
  value_,
  parent_value,
  field_value
) AS
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

CREATE OR REPLACE VIEW v_sepo_std_attr_properties (
  name,
  isnumber,
  isdouble,
  islist
) AS
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

CREATE OR REPLACE VIEW v_sepo_std_objects
AS
SELECT
  o.id AS id_obj,
  o.id_record,
  o.id_tool,
  o.signvo,
  o.namevo,
  o.shortname,
  o.fullname,
  o.gost,
  r.f_key AS tblkey,
  pr.f_key AS reckey,
  t.f_table AS table_,
  omp.id_omp AS bocode,
  k.unvcode,
  k.itemtype AS objtype,
  k.Sign AS ksign,
  k.name AS kname
FROM
  sepo_std_objects o
  JOIN
  sepo_std_table_records r
  ON
      r.id = o.id_record
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = r.id_table
  JOIN
  sepo_std_tables t
  ON
      t.id = pr.id_table
  left JOIN
  sepo_std_objects_to_omp omp
  ON
      omp.id_stdobj = o.id
  left JOIN
  konstrobj k
  ON
      k.bocode = omp.id_omp;

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
  o.bocode,
  o.objtype,
  NULL AS art_id,
  o.table_,
  o.tblkey,
  o.reckey,
  o.signvo,
  o.unvcode,
  o.ksign,
  o.kname
FROM
  v_sepo_tp_tools t
  JOIN
  v_sepo_std_objects o
  ON
      o.reckey = t.reckey
    AND
      o.tblkey = t.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog != 3709;

DROP VIEW v_sepo_tp_fixture_old;

CREATE TABLE sepo_tp_workshops_subst (
  id NUMBER PRIMARY KEY,
  tp_workshop VARCHAR2(100) NOT NULL,
  subst_workshop VARCHAR2(100) NOT NULL,
  subst_section VARCHAR2(100) NULL
);

INSERT INTO sepo_tp_workshops_subst VALUES (1, '414о', '414', NULL);
INSERT INTO sepo_tp_workshops_subst VALUES (2, '425о', '425', NULL);
INSERT INTO sepo_tp_workshops_subst VALUES (3, '308о', '308', NULL);
INSERT INTO sepo_tp_workshops_subst VALUES (4, '468о', '468', NULL);
INSERT INTO sepo_tp_workshops_subst VALUES (5, '343о', '343', NULL);
INSERT INTO sepo_tp_workshops_subst VALUES (6, '467/2', '467', '467-2');
INSERT INTO sepo_tp_workshops_subst VALUES (7, '92пр', '92', NULL);

CREATE OR REPLACE VIEW v_sepo_tp_opers
AS
SELECT
  op.id AS id_op,
  op.id_tp,
  op.key_,
  op.reckey,
  op.order_,
  op.date_,
  op.num,
  op.place,
  op.tpkey,
  f1.f_value AS opercode,
  f2.f_value AS opername,
  f3.f_value AS cex,
  sub.subst_workshop AS subcex,
  f4.f_value AS instruction,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  top.code AS topcode,
  w.code AS wscode,
  sc.code AS seccode,
  sc.Sign AS secsign,
  f5.f_value AS koid,
  CASE
    WHEN regexp_like(f5.f_value, '^[-]?\d+([\.,]\d+)?$')
      THEN To_Number(REPLACE(f5.f_value, ',', '.'))
    ELSE 1
  END koid_num,
  f6.f_value AS dopname
FROM
  sepo_tp_opers op
  left JOIN
  sepo_tp_oper_comments c
  ON
      c.id_oper = op.id
  left JOIN
  sepo_tp_oper_fields f1
  ON
      f1.id_oper = op.id
    AND
      f1.field_name = 'Копк'
  left JOIN
  sepo_tp_oper_fields f2
  ON
      f2.id_oper = op.id
    AND
      f2.field_name = 'ОПЕР'
  left JOIN
  sepo_tp_oper_fields f3
  ON
      f3.id_oper = op.id
    AND
      f3.field_name = 'ЦЕХ'
  left JOIN
  sepo_tp_oper_fields f4
  ON
      f4.id_oper = op.id
    AND
      f4.field_name = 'К_тб'
  left JOIN
  sepo_tp_oper_fields f5
  ON
      f5.id_oper = op.id
    AND
      f5.field_name = 'КОИД'
  left JOIN
  sepo_tp_oper_fields f6
  ON
      f6.id_oper = op.id
    AND
      f6.field_name = 'Доп'
  left JOIN
  technology_operations top
  ON
      top.description = op.reckey
  left JOIN
  sepo_tp_workshops_subst sub
  ON
      f3.f_value = sub.tp_workshop
  left JOIN
  divisionobj d
  ON
      d.division_type IN (104, 701)
    AND
      d.wscode = coalesce(sub.subst_workshop, f3.f_value)
  left JOIN
  workshops w
  ON
      w.dobjcode = d.code
  left JOIN
  divisionobj ds
  ON
      ds.wscode = sub.subst_section
  left JOIN
  sections sc
  ON
      sc.dobjcode = ds.code;

ALTER TABLE sepo_tp_opers_temp ADD seccode NUMBER;
ALTER TABLE sepo_tp_opers_temp ADD koid NUMBER;
ALTER TABLE sepo_tp_opers_temp ADD dopname VARCHAR2(1000);

CREATE OR REPLACE VIEW v_sepo_tp_steps
AS
SELECT
  s.id AS id_step,
  s.operkey,
  s.key_ AS perehkey,
  f1.f_value AS stepname,
  f2.f_value AS stepnumber,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  omp.stepcode AS ompcode,
  s.num,
  f3.f_value AS pkvalue,
  s.order_
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
  sepo_tp_step_fields f3
  ON
      f3.id_step = s.id
    AND
      f3.field_name = 'ПК'
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

ALTER TABLE sepo_tp_steps_temp ADD order_ NUMBER;
ALTER TABLE sepo_tp_steps_temp ADD pkvalue VARCHAR2(100);

UPDATE omp_sepo_properties
SET
  property_value = '1.0.0.4'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2018_11_11_v1'
WHERE
    id = 2;