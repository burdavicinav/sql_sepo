SPOOL log.txt

-- 2019_04_14_v1 -> 2019_06_02_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2019_04_14_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

-- создание соответствия для наименований цехов
SELECT * FROM sepo_tp_workshops_subst;

UPDATE sepo_tp_workshops_subst
SET
  subst_section = '92-2'
WHERE
    tp_workshop = '92пр';

INSERT INTO sepo_tp_workshops_subst (
  id, tp_workshop, subst_workshop
)
VALUES (
  8, 'ЦЗЛВК', '350'
);

CREATE OR REPLACE VIEW v_sepo_tp_opers (
  id_op,
  id_tp,
  key_,
  reckey,
  order_,
  date_,
  num,
  place,
  tpkey,
  opercode,
  opername,
  cex,
  subcex,
  instruction,
  remark,
  topcode,
  wscode,
  seccode,
  secsign,
  koid,
  koid_num,
  dopname
) AS
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
  sepo_tech_oper_links ol
  ON
      ol.reckey = op.reckey
  left JOIN
  technology_operations top
  ON
      To_Number(top.opercode) || '-' || To_Number(coalesce(top.variantcode, '00'))
        = To_Number(ol.opercode) || '-' || To_Number(coalesce(ol.variantcode, '00'))
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
      ds.division_type = 106
    AND
      ds.wscode = sub.subst_section
  left JOIN
  sections sc
  ON
      sc.dobjcode = ds.code;

CREATE OR REPLACE VIEW v_sepo_tech_processes (
  id,
  kind,
  key_,
  designation,
  name,
  doc_id,
  dce_cnt,
  dce_cnt_tp,
  tptype,
  remark,
  wscode,
  sectioncode
) AS
SELECT
  t.id,
  t.kind,
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  t.dce_cnt,
  t.dce_cnt_tp,
  CASE
    WHEN t.kind = 1 AND t.dce_cnt <= 1 THEN 0
    WHEN t.kind IN (6,7) OR dce_cnt > 1 THEN 3
  END tptype,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  w.code AS wscode,
  s.code AS sectioncode
FROM
  v_sepo_tech_processes_base t
  left JOIN
  sepo_tp_comments c
  ON
      c.id_tp = t.id
  left JOIN
  sepo_tp_fields f1
  ON
      f1.id_tp = t.id
    AND
      f1.field_name = 'Ceh'
  left JOIN
  sepo_tp_workshops_subst sb
  ON
      sb.tp_workshop = f1.f_value
  left JOIN
  divisionobj dv
  ON
      dv.division_type IN (104, 701)
    AND
      dv.wscode = coalesce(sb.subst_workshop, f1.f_value)
  left JOIN
  workshops w
  ON
      w.dobjcode = dv.code
  left JOIN
  divisionobj ds
  ON
      ds.division_type = 106
    AND
      ds.wscode = coalesce(sb.subst_workshop, f1.f_value)
  left JOIN
  sections s
  ON
      s.dobjcode = ds.code;

INSERT INTO sepo_task_folder_list (
  id, name, id_parent
)
VALUES (
  7, 'Присоединенные файлы', 2
);

UPDATE sepo_task_list
SET
  name = 'Загрузка',
  id_folder = 7
WHERE
    id = 10;

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  27, 'Объекты', 7
);

CREATE SEQUENCE sq_sepo_fixture_af_objects;

CREATE TABLE sepo_fixture_af_objects (
  id NUMBER PRIMARY KEY,
  id_type NUMBER UNIQUE NOT NULL,
  id_file_group NUMBER NULL,
  id_owner NUMBER NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_fixture_af_objects
BEFORE INSERT ON sepo_fixture_af_objects
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_fixture_af_objects.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_fixture_af_objects
AS
SELECT
  o.id,
  o.id_type,
  t.name AS typename,
  g.name AS filegroup,
  n.name AS owner
FROM
  sepo_fixture_af_objects o
  JOIN
  businessobj_types t
  ON
      t.code = o.id_type
  left JOIN
  attachments_groups g
  ON
      g.code = o.id_file_group
  LEFT JOIN
  owner_name n
  ON
      n.owner = o.id_owner;

CREATE OR REPLACE VIEW v_sepo_fixture_af_load
AS
SELECT
  d.id,
  d.doc_id,
  d.filename,
  d.designatio,
  d.name,
  bo.code AS bocode,
  bo.TYPE AS botype,
  bo.doccode AS doccode,
  bo.revision,
  sbo.id_file_group,
  sbo.id_owner,
  bt.name AS botypename
FROM
  sepo_osn_docs d
  JOIN
  business_objects bo
  ON
      bo.name = d.designatio
  JOIN
  businessobj_types bt
  ON
      bt.code = bo.TYPE
  JOIN
  sepo_fixture_af_objects sbo
  ON
      sbo.id_type = bo.TYPE
WHERE
    coalesce(bo.owner, -1) = coalesce(sbo.id_owner, -1);

CREATE SEQUENCE sq_sepo_fixture_af_result_temp;

CREATE GLOBAL TEMPORARY TABLE sepo_fixture_af_result_temp (
  id NUMBER,
  iddoc NUMBER,
  filename VARCHAR2(1000),
  objsign VARCHAR2(200),
  objtype VARCHAR2(200),
  revision NUMBER,
  state NUMBER
) ON COMMIT PRESERVE ROWS;

UPDATE omp_sepo_properties
SET
  property_value = '2.0.7092.42383'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_06_02_v1'
WHERE
    id = 2;

COMMIT;