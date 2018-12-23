-- 2018_08_08_v1 -> 2018_11_10_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_08_08_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

DROP VIEW v_sepo_std_tech_attrs;
DROP VIEW v_sepo_std_tp_params_link;
DROP VIEW v_sepo_std_tp_params;
DROP VIEW v_sepo_std_expressions;

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
      'IEM_ASPARENT',
      'IEM_LIST'
    );

DROP VIEW v_sepo_std_formuls;

CREATE OR REPLACE VIEW v_sepo_std_expr_contents
AS
WITH exc(id, id_table, f_longname, f_shortname, rule, ind, field)
AS
(
  SELECT
    id,
    id_table,
    f_longname,
    f_shortname,
    f_data,
    1,
    regexp_substr(f_data, '\{.*?\[?F\d+\]?.*\}|\[[^]F]*\]', 1, 1)
  FROM
    sepo_std_table_fields
  WHERE
      f_entermode = 'IEM_EXPRESSION'
  UNION ALL
  SELECT
    id,
    id_table,
    f_longname,
    f_shortname,
    rule,
    ind + 1,
    regexp_substr(rule, '\{.*?\[?F\d+\]?.*\}|\[[^]F]*\]', 1, ind + 1)
  FROM
    exc
  WHERE
      regexp_instr(rule, '\{.*?\[?F\d+\]?.*\}|\[[^]F]*\]', 1, ind + 1) > 0
)
SELECT
  exc.id,
  exc.id_table,
  exc.f_longname,
  exc.f_shortname,
  exc.rule,
  exc.ind,
  CASE
    WHEN regexp_substr(exc.field, 'F\d+') IS NULL THEN exc.field
    ELSE regexp_substr(exc.field, 'F\d+')
  END AS field
FROM
  exc;

CREATE OR REPLACE VIEW v_sepo_std_tp_params
AS
SELECT
  r.id AS id_record,
  r.f_key AS reckey,
  f.id AS id_expr,
  f.id_table,
  regexp_replace(f.field, '\[|\]', '') AS tp_param
FROM
  v_sepo_std_expr_contents f,
  sepo_std_records r
WHERE
    regexp_substr(coalesce(f.field, 'F0'), 'F\d+') IS NULL
  AND
    r.id_table = f.id_table;

CREATE OR REPLACE VIEW v_sepo_std_expr_cont_details
AS
SELECT
  r.id AS id_record,
  r.f_key,
  r.id_table,
  t.f_table,
  rl.id AS id_field_rule,
  rl.f_longname AS rule_name,
  rl.rule,
  rl.ind AS ordernum,
  rl.field,
  f.id AS id_field,
  f.f_longname AS field_name,
  f.f_entermode AS field_mode,
  pf.id AS id_p_field,
  pf.f_longname AS p_field_name,
  pf.field AS p_field,
  rc.field_value,
  prc.field_value AS p_field_value
FROM
  sepo_std_tables t
  JOIN
  sepo_std_table_records r
  ON
      r.id_table = t.id
  JOIN
  v_sepo_std_expr_contents rl
  ON
      rl.id_table = r.id_table
  left JOIN
  sepo_std_table_fields f
  ON
      f.id_table = rl.id_table
    AND
      f.field = rl.field
  left JOIN
  sepo_std_fields pf
  ON
      pf.f_longname = f.f_longname
  left JOIN
  sepo_std_table_rec_contents rc
  ON
      rc.id_record = r.id
    AND
      rc.id_field = f.id
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = t.id
  left JOIN
  sepo_std_record_contents prc
  ON
      prc.id_record = pr.id
    AND
      prc.id_field = pf.id
ORDER BY
  r.id,
  rl.f_longname,
  rl.ind;

CREATE OR REPLACE VIEW v_sepo_std_field_values
AS
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
  END, '~', ' ') AS imp_field_value
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
      pc.id_field = pf.id;

DROP TABLE sepo_std_expressions_temp;

CREATE GLOBAL TEMPORARY TABLE sepo_std_field_values_temp (
  id_record NUMBER,
  id_field NUMBER,
  field_mode VARCHAR2(50),
  field_name VARCHAR2(100),
  field_value VARCHAR2(1000)
) ON COMMIT PRESERVE ROWS;

ALTER TABLE sepo_std_field_values_temp ADD field_number NUMBER;

ALTER TABLE sepo_osn_se MODIFY field2 VARCHAR2(200);

DROP TABLE sepo_std_tp_params;

DROP VIEW v_sepo_std_tp_params;

CREATE SEQUENCE sq_sepo_std_expressions;

-- значения формул
CREATE TABLE sepo_std_expressions (
  id NUMBER PRIMARY KEY,
  id_record NUMBER NOT NULL REFERENCES sepo_std_table_records(id),
  id_expr NUMBER NOT NULL REFERENCES sepo_std_table_fields(id),
  expr_value VARCHAR2(1000) NULL,
  tp_depend NUMBER DEFAULT 0 NOT NULL,
  id_tool NUMBER NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_expressions
BEFORE INSERT ON sepo_std_expressions
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_expressions.NEXTVAL;
END;
/

-- временная таблица для выполнения I этапа парсинга
CREATE GLOBAL TEMPORARY TABLE sepo_std_expressions_temp (
  id_record NUMBER NOT NULL,
  id_expr NUMBER NOT NULL,
  expr_value VARCHAR2(1000) NULL,
  tp_depend NUMBER DEFAULT 0 NOT NULL
) ON COMMIT PRESERVE ROWS;

-- значения полей из формулы
CREATE TABLE sepo_std_expr_field_values (
  id_record NUMBER NOT NULL,
  id_expr NUMBER NOT NULL,
  token VARCHAR2(10) NOT NULL,
  value_ VARCHAR2(1000)
);

DROP TABLE sepo_std_tp_params_temp;

CREATE GLOBAL TEMPORARY TABLE sepo_std_tp_param_values_temp (
  id_record NUMBER,
  id_field NUMBER,
  id_tool NUMBER,
  param VARCHAR2(100),
  value_ VARCHAR2(4000)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_std_tp_params_temp (
  id_record NUMBER,
  id_field NUMBER,
  param VARCHAR2(100)
) ON COMMIT PRESERVE ROWS;

CREATE TABLE sepo_std_tp_params (
  id NUMBER PRIMARY KEY,
  id_expr NOT NULL REFERENCES sepo_std_expressions(id),
  param VARCHAR2(100) NOT NULL,
  param_value VARCHAR2(4000) NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_tp_params
BEFORE INSERT ON sepo_std_tp_params
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_tp_params.NEXTVAL;
END;
/

DROP TABLE sepo_std_formulas;

DROP VIEW v_sepo_std_formul_on_fields;

DROP VIEW v_sepo_std_dop_data;

DROP VIEW v_sepo_std_formula_names;

CREATE OR REPLACE VIEW v_sepo_std_expressions_group
AS
SELECT
  id,
  id_record,
  id_tool,
  id_expr,
  expr_value
FROM
  sepo_std_expressions
WHERE
    id_tool IS NOT NULL
UNION ALL
SELECT
  f1.id,
  f1.id_record,
  f2.id_tool,
  f1.id_expr,
  f1.expr_value
FROM
  sepo_std_expressions f1
  left JOIN
  sepo_std_expressions f2
  ON
      f1.id_record = f2.id_record
    AND
      f2.id_tool IS NOT NULL
WHERE
    f1.id_tool IS NULL
GROUP BY
  f1.id,
  f1.id_record,
  f2.id_tool,
  f1.id_expr,
  f1.expr_value
ORDER BY
  id_record,
  id_expr;

CREATE OR REPLACE VIEW v_sepo_std_expressions_main
AS
SELECT
  d.id_record,
  d.id_tool,
  d.signvo,
  d.namevo,
  d.shortname,
  d.fullname,
  v.imp_field_value AS gost
FROM
  (
  SELECT
    id_record,
    id_tool,
    Upper(f_longname) AS name,
    expr_value
  FROM
    v_sepo_std_expressions_group g
    JOIN
    sepo_std_table_fields f
    ON
        f.id = g.id_expr
  )
  pivot (
    Max(expr_value)
    FOR name IN (
      'ОБОЗНАЧЕНИЕ ДЛЯ ВО' AS signvo,
      'НАИМЕНОВАНИЕ ДЛЯ ВО' AS namevo,
      'КРАТКОЕ НАИМЕНОВАНИЕ' AS shortname,
      'ПОЛНОЕ НАИМЕНОВАНИЕ' AS fullname)
  ) d
  left JOIN
  v_sepo_std_field_values v
  ON
      v.id_record = d.id_record
    AND
      Upper(v.field_name) = 'ОБОЗНАЧЕНИЕ СТАНДАРТА';

CREATE SEQUENCE sq_sepo_std_objects;

CREATE TABLE sepo_std_objects (
  id NUMBER PRIMARY KEY,
  id_record NUMBER NOT NULL REFERENCES sepo_std_table_records(id),
  id_tool NUMBER NULL REFERENCES sepo_tp_tools(id),
  signvo VARCHAR2(1000) NULL,
  namevo VARCHAR2(1000) NULL,
  shortname VARCHAR2(1000) NULL,
  fullname VARCHAR2(1000) NULL,
  gost VARCHAR2(1000) NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_objects
BEFORE INSERT ON sepo_std_objects
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_objects.NEXTVAL;
END;
/

CREATE TABLE sepo_std_objects_to_omp (
  id_stdobj NUMBER REFERENCES sepo_std_objects(id),
  id_omp NUMBER,
  PRIMARY KEY (id_stdobj, id_omp)
);

CREATE OR REPLACE VIEW v_sepo_std_import
AS
SELECT
  r.id AS id_record,
  pr.id AS id_parent_record,
  f.lvl_classify,
  f.lvl_type,
  pr.f_level,
  pr.f_key AS reckey,
  r.f_key AS tblkey,
  t.f_table,
  d.id AS id_obj,
  d.id_tool,
  d.signvo,
  d.namevo,
  d.shortname,
  d.fullname,
  d.gost,
  sh.omp_name AS scheme_name
FROM
  sepo_std_table_records r
  JOIN
  sepo_std_tables t
  ON
      r.id_table = t.id
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = r.id_table
  JOIN
  v_sepo_std_folders f
  ON
      pr.f_level = f.lvl
  left JOIN
  sepo_std_objects d
  ON
    r.id = d.id_record
  JOIN
  v_sepo_std_schemes sh
  ON
      sh.id_record = pr.id;

DROP TABLE sepo_std_attrs_temp;

CREATE GLOBAL TEMPORARY TABLE sepo_std_attr_values_temp (
  id_record NUMBER,
  id_tool NUMBER,
  id_attr NUMBER,
  shortname VARCHAR2(100),
  type_ VARCHAR2(100),
  value_ VARCHAR2(1000),
  enum_value NUMBER
) ON COMMIT PRESERVE ROWS;

SELECT * FROM omp_sepo_properties;

UPDATE omp_sepo_properties
SET
  property_value = '1.0.0.3'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2018_11_10_v1'
WHERE
    id = 2;