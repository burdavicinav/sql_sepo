SPOOL log.txt

-- 2019_06_02_v1 -> 2019_06_03_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2019_06_02_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

CREATE SEQUENCE sq_sepo_tp_workshop_owner;

CREATE TABLE sepo_tp_workshop_owner (
  id NUMBER PRIMARY KEY,
  wscode NUMBER UNIQUE,
  owner NUMBER NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_workshop_owner
BEFORE INSERT ON sepo_tp_workshop_owner
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_workshop_owner.NEXTVAL;
END;
/

INSERT INTO sepo_tp_workshop_owner (wscode)
SELECT
  DISTINCT wscode
FROM
  v_sepo_tech_processes
WHERE
    wscode IS NOT NULL;

CREATE OR REPLACE VIEW v_sepo_tp_workshop_owner
AS
SELECT
  l.id,
  dv.code AS wscode,
  dv.Sign AS wssign,
  ow.owner,
  ow.name AS ownername
FROM
  sepo_tp_workshop_owner l
  JOIN
  workshops w
  ON
      w.code = l.wscode
  JOIN
  divisionobj dv
  ON
      dv.code = w.dobjcode
  left JOIN
  owner_name ow
  ON
      ow.owner = l.owner;

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  28, 'Владельцы', 4
);

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
  sectioncode,
  ownercode
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
  s.code AS sectioncode,
  ow.owner AS ownercode
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
      s.dobjcode = ds.code
  left JOIN
  sepo_tp_workshop_owner ow
  ON
      ow.wscode = w.code;

UPDATE omp_sepo_properties
SET
  property_value = '2.0.7093.42875'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_06_03_v1'
WHERE
    id = 2;

COMMIT;