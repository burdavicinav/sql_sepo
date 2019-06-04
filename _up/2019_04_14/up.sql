SPOOL log.txt

-- 2019_03_17_v1 -> 2019_04_14_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2019_03_17_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

CREATE SEQUENCE sq_sepo_tech_oper_links;

CREATE TABLE sepo_tech_oper_links (
  id NUMBER PRIMARY KEY,
  opercode VARCHAR2(9) NOT NULL,
  variantcode VARCHAR2(2) NULL,
  name VARCHAR2(150) NOT NULL,
  reckey NUMBER NULL,
  tpopercode NUMBER NULL,
  tpopername VARCHAR2(150) NULL,

  UNIQUE(opercode, variantcode)
);

CREATE OR REPLACE TRIGGER t_sepo_tech_oper_links
BEFORE INSERT ON sepo_tech_oper_links
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tech_oper_links.NEXTVAL;
END;
/

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  26, 'Связь технологический операций', 4
);

--SELECT * FROM sepo_tech_oper_links;

--SELECT
--  opercode,
--  variantcode,
--  Count(DISTINCT id)
--FROM
--  sepo_tech_oper_links
--GROUP BY
--  opercode, variantcode
--HAVING
--  Count(DISTINCT id) > 1;

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
      top.opercode || top.variantcode = ol.opercode || ol.variantcode
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

UPDATE omp_sepo_properties
SET
  property_value = '2.0.7043.41699'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_04_14_v1'
WHERE
    id = 2;

COMMIT;