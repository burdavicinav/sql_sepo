-- 2018_02_25_v1 -> 2018_06_05_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_02_25_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

INSERT INTO sepo_task_folder_list (
  id, name, id_parent
)
VALUES (
  3, 'Импорт стандартной оснастки', 1
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  12, 'Загрузка данных из файлов', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  13, 'Схемы атрибутов', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  14, 'Атрибуты', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  16, 'Обновить структуру БД', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  15, 'Атрибуты FoxPro', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  18, 'Импорт', 3
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  19, 'Создание классификатора', 3
);

INSERT INTO sepo_task_folder_list (
  id, name, id_parent
)
VALUES (
  4, 'Импорт технологических процессов', 1
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  20, 'Импорт', 4
);

CREATE SEQUENCE sq_sepo_std_folders;

CREATE TABLE sepo_std_folders (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_owner NUMBER,
  f_level NUMBER,
  f_name VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_folders
BEFORE INSERT ON sepo_std_folders
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_folders.NEXTVAL;
END;
/

CREATE TABLE sepo_std_folder_codes (
  id_folder NUMBER,
  code VARCHAR2(10)
);

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(3753, 'В');

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(3727, 'М');

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(4129, 'П');

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(3758, 'Р');

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(3897, 'С');

INSERT INTO sepo_std_folder_codes
(id_folder, code)
VALUES
(4042, 'Н');

ALTER TABLE sepo_std_folder_codes ADD key_ NUMBER;
ALTER TABLE sepo_std_folder_codes ADD name VARCHAR2(50);

UPDATE sepo_std_folder_codes SET key_ = 8, name = 'Вспомогательный инструмент'
WHERE
    id_folder = 3753;

UPDATE sepo_std_folder_codes SET key_ = 1, name = 'Мерительный инструмент'
WHERE
    id_folder = 3727;

UPDATE sepo_std_folder_codes SET key_ = 4, name = 'Приспособления'
WHERE
    id_folder = 4129;

UPDATE sepo_std_folder_codes SET key_ = 2, name = 'Режущий инструмент'
WHERE
    id_folder = 3758;

UPDATE sepo_std_folder_codes SET key_ = 9, name = 'Слесарный инструмент'
WHERE
    id_folder = 3897;

UPDATE sepo_std_folder_codes SET key_ = 3, name = 'Тара'
WHERE
    id_folder = 4042;

INSERT INTO sepo_std_folder_codes
(id_folder, code, key_, name)
VALUES
(null, 'Ш', 5, 'Штампы');

INSERT INTO sepo_std_folder_codes
(id_folder, code, key_, name)
VALUES
(null, 'Ф', 6, 'Прессформы');

INSERT INTO sepo_std_folder_codes
(id_folder, code, key_, name)
VALUES
(null, 'А', 7, 'Абразивный инструмент');

CREATE SEQUENCE sq_sepo_std_fields;

CREATE TABLE sepo_std_fields (
  id NUMBER PRIMARY KEY,
  field VARCHAR2(50),
  f_longname VARCHAR2(50),
  f_datatype VARCHAR2(20),
  f_entermode VARCHAR2(20),
  f_data VARCHAR2(50)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_fields
BEFORE INSERT ON sepo_std_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_tables;

CREATE TABLE sepo_std_tables (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_table VARCHAR2(10) NOT NULL,
  f_descr VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_tables
BEFORE INSERT ON sepo_std_tables
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_tables.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_records;

CREATE TABLE sepo_std_records (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_level NUMBER,
  id_table NUMBER NULL REFERENCES sepo_std_tables(id)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_records
BEFORE INSERT ON sepo_std_records
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_records.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_record_contents;

CREATE TABLE sepo_std_record_contents (
  id NUMBER PRIMARY KEY,
  id_record NUMBER NOT NULL REFERENCES sepo_std_records(id),
  id_field NUMBER NOT NULL REFERENCES sepo_std_fields(id),
  field_value VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_record_contents
BEFORE INSERT ON sepo_std_record_contents
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_record_contents.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_table_fields;

CREATE TABLE sepo_std_table_fields (
  id NUMBER PRIMARY KEY,
  id_table NUMBER NOT NULL REFERENCES sepo_std_tables(id),
  field VARCHAR2(50) NOT NULL,
  f_longname VARCHAR2(50),
  f_datatype VARCHAR2(20),
  f_entermode VARCHAR2(20),
  f_data VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_table_fields
BEFORE INSERT ON sepo_std_table_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_table_fields.NEXTVAL;
END;
/

CREATE INDEX i_sepo_std_table_fields_name
ON sepo_std_table_fields(f_longname);

CREATE SEQUENCE sq_sepo_std_table_records;

CREATE TABLE sepo_std_table_records (
  id NUMBER PRIMARY KEY,
  f_key NUMBER NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_table_records
BEFORE INSERT ON sepo_std_table_records
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_table_records.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_table_rec_contents;

CREATE TABLE sepo_std_table_rec_contents (
  id NUMBER PRIMARY KEY,
  id_record NUMBER NOT NULL REFERENCES sepo_std_table_records(id),
  id_field NUMBER NOT NULL REFERENCES sepo_std_table_fields(id),
  field_value VARCHAR2(200)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_tbl_rec_contents
BEFORE INSERT ON sepo_std_table_rec_contents
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_table_rec_contents.NEXTVAL;
END;
/

ALTER TABLE sepo_std_table_records
ADD id_table NUMBER NOT NULL REFERENCES sepo_std_tables(id);

ALTER TABLE sepo_std_table_fields
ADD f_shortname VARCHAR2(50);

CREATE OR REPLACE VIEW v_sepo_osn_se_sp (
  art_id,
  o_vo,
  osn_type,
  type_sign
) AS
SELECT
  art_id,
  Max(field1) AS field1,
  Max(field3) AS osn_type,
  Max(type_sign) AS type_sign
FROM
  (
  SELECT
    art_id,
    field1,
    field3,
    SubStr(field3, 1, 1) AS type_sign
  FROM
    sepo_osn_se
  UNION ALL
  SELECT
    art_id,
    field1,
    field3,
    SubStr(field3, 1, 1) AS type_sign
  FROM
    sepo_osn_sp
  )
GROUP BY
  art_id;

CREATE OR REPLACE VIEW v_sepo_fixture_nodes_load (
  id,
  art_id,
  doc_id,
  designation,
  name,
  section_id,
  chkindate,
  modifdate,
  o_vo,
  osn_type,
  id_type
) AS
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
  s.o_vo,
  s.osn_type,
  t.id_type
FROM
  sepo_osn_all a,
  v_sepo_osn_se_sp s,
  sepo_osn_types t
WHERE
    a.section_id IN (
      100000042,
      100000043,
      100000047
    )
  AND
    a.art_id = s.art_id(+)
  AND
    s.type_sign = t.shortname(+)
  AND
    EXISTS
    (
      SELECT
        1
      FROM
        sepo_osn_sostav sp,
        sepo_osn_all el
      WHERE
          sp.proj_aid = a.art_id
        AND
          el.art_id = sp.part_aid
    )
  AND
    a.art_id > 0
  AND
    designation IS NOT NULL
ORDER BY
  designation;

CREATE OR REPLACE VIEW v_sepo_fixture_load (
  id,
  art_id,
  doc_id,
  designation,
  name,
  section_id,
  chkindate,
  modifdate,
  o_vo,
  osn_type,
  id_type
) AS
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
  s.o_vo,
  s.osn_type,
  t.id_type
FROM
  sepo_osn_all a,
  v_sepo_osn_se_sp s,
  sepo_osn_types t
WHERE
    a.section_id IN (100000042, 100000047)
  AND
    NOT EXISTS
    (
      SELECT
        1
      FROM
        sepo_osn_sostav sp,
        sepo_osn_all el
      WHERE
          sp.proj_aid = a.art_id
        AND
          el.art_id = sp.part_aid
    )
  AND
    a.art_id = s.art_id(+)
  AND
    s.type_sign = t.shortname(+)
  AND
    a.art_id > 0
  AND
    designation IS NOT NULL
UNION ALL
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
  s.o_vo,
  s.osn_type,
  t.id_type
FROM
  sepo_osn_all a,
  v_sepo_osn_se_sp s,
  sepo_osn_types t
WHERE
    a.section_id = 100000043
  AND
    NOT EXISTS
    (
      SELECT
        1
      FROM
        sepo_osn_sostav sp,
        sepo_osn_all el
      WHERE
          sp.proj_aid = a.art_id
        AND
          el.art_id = sp.part_aid
    )
  AND
    NOT EXISTS
    (
      SELECT
        1
      FROM
        sepo_osn_sostav sp
      WHERE
          sp.part_aid = a.art_id
    )
  AND
    a.art_id = s.art_id(+)
  AND
    s.type_sign = t.shortname(+)
  AND
    a.art_id > 0
  AND
    designation IS NOT NULL;

CREATE SEQUENCE sq_sepo_std_enum_folders;

CREATE TABLE sepo_std_enum_folders (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_name VARCHAR2(100),
  f_owner NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_enum_folders
BEFORE INSERT ON sepo_std_enum_folders
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_enum_folders.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_enum_list;

CREATE TABLE sepo_std_enum_list (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_name VARCHAR2(100),
  f_owner NUMBER,
  f_int VARCHAR2(1000),
  tcentity VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_enum_list
BEFORE INSERT ON sepo_std_enum_list
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_enum_list.NEXTVAL;
END;
/

CREATE INDEX i_sepo_std_enum_list_key
ON sepo_std_enum_list(f_key);

CREATE SEQUENCE sq_sepo_std_enum_contents;

CREATE TABLE sepo_std_enum_contents (
  id NUMBER PRIMARY KEY,
  id_enum NUMBER NOT NULL REFERENCES sepo_std_enum_list(id),
  f_key NUMBER,
  f_str VARCHAR2(100),
  f_int NUMBER,
  f_dbl NUMBER,
  f_name VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_enum_contents
BEFORE INSERT ON sepo_std_enum_contents
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_enum_contents.NEXTVAL;
END;
/

ALTER TABLE sepo_std_table_fields ADD enm_owner NUMBER;

ALTER TABLE sepo_std_table_fields ADD enm_type VARCHAR2(10);

CREATE OR REPLACE VIEW v_sepo_std_schemes_build
AS
WITH class(
  id,
  f_table,
  h_key,
  h_owner,
  h_level,
  f_name,
  tbl_descr,
  lvl,
  scheme
)
AS
(
  SELECT
    r.id,
    t.f_table,
    r.f_key,
    f.f_owner,
    f.f_level,
    f.f_name,
    t.f_descr,
    0,
    f.f_name
  FROM
    sepo_std_records r,
    sepo_std_tables t,
    sepo_std_folders f
  WHERE
      r.id_table = t.id
    AND
      f.f_level = r.f_level
UNION ALL
  SELECT
    c.id,
    c.f_table,
    f.f_key,
    f.f_owner,
    f.f_level,
    c.f_name,
    c.tbl_descr,
    c.lvl + 1,
    CASE
      WHEN f.f_owner = 0 THEN ''
      ELSE f.f_name || ' '
    END || c.scheme
  FROM
    class c,
    sepo_std_folders f
  WHERE
      f.f_level = c.h_owner
)
SELECT
  c.id,
  c.h_key,
  c.h_level,
  c.f_table,
  c.f_name,
  tbl_descr,
  c.scheme
FROM
  class c
WHERE
    h_owner = 0
ORDER BY
  f_table;

CREATE TABLE sepo_std_schemes (
  id_record NUMBER PRIMARY KEY,
  f_key NUMBER NOT NULL,
  f_level NUMBER NOT NULL,
  scheme_name VARCHAR2(1000) NOT NULL,

  FOREIGN KEY(id_record) REFERENCES sepo_std_records(id)
);

ALTER TABLE sepo_std_schemes ADD omp_name VARCHAR2(100) NOT NULL UNIQUE;
ALTER TABLE sepo_std_schemes ADD tname VARCHAR2(50) NOT NULL UNIQUE;
ALTER TABLE sepo_std_schemes ADD istable NUMBER DEFAULT 0 NOT NULL
  CHECK (istable IN (0, 1));
ALTER TABLE sepo_std_schemes ADD isedit NUMBER DEFAULT 0 NOT NULL
  CHECK (isedit IN (0, 1));

CREATE GLOBAL TEMPORARY TABLE sepo_std_schemes_temp (
  id_record NUMBER,
  f_key NUMBER,
  f_level NUMBER,
  tname VARCHAR2(50),
  scheme_name VARCHAR2(1000),
  omp_name VARCHAR2(100)
) ON COMMIT PRESERVE ROWS;

DROP TABLE sepo_std_schemes_temp

CREATE OR REPLACE VIEW v_sepo_std_attr_properties
AS
SELECT
  f.f_longname AS name,
  Min(
    CASE
      WHEN regexp_like(cs.field_value, '^\d+$')
        OR cs.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isnumber,
  Min(
    CASE
      WHEN regexp_like(cs.field_value, '^\d*[\.,]\d+$')
        OR cs.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isdouble,
  Min(
    CASE
      WHEN f.f_entermode = 'IEM_LIST' THEN 1
      ELSE 0
    END
  ) AS islist
FROM
  sepo_std_table_rec_contents cs,
  sepo_std_table_fields f
WHERE
    cs.id_field = f.id
  AND
    f.f_entermode IN ('IEM_SIMPLE', 'IEM_LIST')
GROUP BY
  f.f_longname;

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
    WHEN isnumber = 1 AND isdouble = 0 THEN 3
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
    f.f_entermode = 'IEM_SIMPLE';

CREATE OR REPLACE VIEW v_sepo_std_list_attrs
AS
SELECT
  f.id AS id_attr,
  f.id_table,
  f.field,
  f.f_datatype,
  f.f_entermode,
  f.f_data,
  a.attr_name,
  a.omp_name,
  a.omp_type,
  a.id_enum,
  a.enum_name,
  a.id_omp_enum,
  a.omp_enum_name
FROM
  (
  SELECT
    a.name AS attr_name,
    CASE
      WHEN Row_Number() OVER (PARTITION BY a.name ORDER BY el.id) = 1 THEN a.name
    ELSE
      a.name || '_' || Row_Number() OVER (PARTITION BY a.name ORDER BY el.id)
    END AS omp_name,
    10 AS omp_type,
    el.id AS id_enum,
    el.f_name AS enum_name,
    v.code AS id_omp_enum,
    v.name AS omp_enum_name
  FROM
    v_sepo_std_attr_properties a,
    sepo_std_table_fields f,
    sepo_std_enum_list el,
    obj_enumerations v
  WHERE
      a.islist = 1
    AND
      a.name = f.f_longname
    AND
      el.f_key = f.enm_owner
    AND
      el.f_name = v.name(+)
  GROUP BY
    a.name,
    a.isnumber,
    a.isdouble,
    a.islist,
    el.id,
    el.f_name,
    v.code,
    v.name
  ) a
  JOIN
  sepo_std_table_fields f
  ON
      a.attr_name = f.f_longname
  JOIN
  sepo_std_enum_list e
  ON
      e.f_key = f.enm_owner
    AND
      e.id = a.id_enum;

CREATE OR REPLACE VIEW v_sepo_std_attrs
AS
SELECT
  a.id_attr,
  a.id_table,
  t.f_table AS tname,
  a.field,
  a.f_datatype,
  a.f_entermode,
  a.f_data,
  a.attr_name,
  a.omp_name,
  a.omp_type,
  a.id_enum,
  a.enum_name,
  a.id_omp_enum,
  a.omp_enum_name,
--  sh.id_record,
--  sh.f_level AS high_level,
--  sh.omp_name AS scheme
  r.id AS id_record
FROM
  (
  SELECT
    id_attr,
    id_table,
    field,
    f_datatype,
    f_entermode,
    f_data,
    attr_name,
    attr_name AS omp_name,
    omp_type,
    NULL AS id_enum,
    NULL AS enum_name,
    NULL AS id_omp_enum,
    NULL AS omp_enum_name
  FROM
    v_sepo_std_simple_attrs
  UNION ALL
  SELECT
    id_attr,
    id_table,
    field,
    f_datatype,
    f_entermode,
    f_data,
    attr_name,
    omp_name,
    omp_type,
    id_enum,
    enum_name,
    id_omp_enum,
    omp_enum_name
  FROM
    v_sepo_std_list_attrs
  ) a
  JOIN
  sepo_std_records r
  ON
      a.id_table = r.id_table
  JOIN
  sepo_std_tables t
  ON
      a.id_table = t.id;
--  JOIN
--  sepo_std_tables t
--  ON
--      a.id_table = t.id
--  JOIN
--  sepo_std_records r
--  ON
--      r.id_table = t.id
--  JOIN
--  sepo_std_schemes sh
--  ON
--      sh.id_record = r.id;

CREATE OR REPLACE VIEW v_sepo_std_schemes
AS
SELECT
  s.id_record,
  b.f_table,
  b.h_level,
  b.f_name,
  b.tbl_descr,
  s.scheme_name,
  s.omp_name,
  s.istable,
  s.isedit
FROM
  v_sepo_std_schemes_build b,
  sepo_std_schemes s
WHERE
    b.id = s.id_record;

CREATE OR REPLACE VIEW v_sepo_std_tables
AS
SELECT
  t.id,
  r.id AS id_record,
  r.f_level,
  t.f_table,
  t.f_descr
FROM
  sepo_std_tables t,
  sepo_std_records r
WHERE
    t.id = r.id_table;

CREATE OR REPLACE VIEW v_sepo_std_formuls
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
    regexp_substr(f_data, '\{.?\[?F\d+\]?\}|\[[^]F]*\]', 1, 1)
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
    regexp_substr(rule, '\{.?\[?F\d+\]?\}|\[[^]F]*\]', 1, ind + 1)
  FROM
    exc
  WHERE
      regexp_instr(rule, '\{.?\[?F\d+\]?\}|\[[^]F]*\]', 1, ind + 1) > 0
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

CREATE OR REPLACE VIEW v_sepo_std_expressions
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
  v_sepo_std_formuls rl
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
WHERE
    1=1
--  AND
--    f.f_entermode = 'IEM_EXPRESSION'
--  AND
--    rl.f_longname = 'Полное наименование'
ORDER BY
  r.id,
  rl.f_longname,
  rl.ind;

CREATE GLOBAL TEMPORARY TABLE sepo_std_expressions_temp (
  id_record NUMBER,
  id_rule NUMBER,
  rule VARCHAR2(100),
  id_field NUMBER,
  field_mode VARCHAR2(50),
  field_name VARCHAR2(100),
  field_value VARCHAR2(1000)
) ON COMMIT PRESERVE ROWS;

CREATE SEQUENCE sq_sepo_tech_processes;

CREATE TABLE sepo_tech_processes (
  id NUMBER PRIMARY KEY,
  key_ NUMBER,
  designation VARCHAR2(200) NOT NULL,
  name VARCHAR2(200),
  doc_id NUMBER NOT NULL,
  kind NUMBER NOT NULL,
  production_id NUMBER,
  version_key NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tech_processes
BEFORE INSERT ON sepo_tech_processes
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tech_processes.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_to_dce;

CREATE TABLE sepo_tp_to_dce (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  key_ NUMBER,
  designation VARCHAR2(200) NOT NULL,
  name VARCHAR2(200),
  art_id NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_to_dce
BEFORE INSERT ON sepo_tp_to_dce
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_to_dce.NEXTVAL;
END;
/

ALTER TABLE sepo_tp_to_dce MODIFY designation VARCHAR2(200) NULL;

CREATE SEQUENCE sq_sepo_tp_entities_legend;

CREATE TABLE sepo_tp_entities_legend (
  id NUMBER PRIMARY KEY,
  f_recordid NUMBER,
  f_type VARCHAR2(100),
  f_name VARCHAR2(100),
  f_tblkey NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_entites_legend
BEFORE INSERT ON sepo_tp_entities_legend
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_entities_legend.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_entities;

CREATE TABLE sepo_tp_entities (
  id NUMBER PRIMARY KEY,
  f_code VARCHAR2(100) NOT NULL,
  f_name VARCHAR2(200) NOT NULL,
  f_recordid NUMBER NOT NULL,
  f_record VARCHAR2(50),
  f_type VARCHAR2(100),
  f_reference NUMBER,
  f_linkcode VARCHAR2(100),
  f_field NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_entites
BEFORE INSERT ON sepo_tp_entities
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_entities.NEXTVAL;
END;
/

ALTER TABLE sepo_tp_entities MODIFY f_recordid NUMBER NULL;
ALTER TABLE sepo_tp_entities MODIFY f_name VARCHAR2(200) NULL;

CREATE SEQUENCE sq_sepo_tp_fields;

CREATE TABLE sepo_tp_fields (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(200),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_fields
BEFORE INSERT ON sepo_tp_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_fields.NEXTVAL;
END;
/

ALTER TABLE sepo_tp_fields MODIFY f_value VARCHAR2(4000);

CREATE OR REPLACE VIEW v_sepo_tp_fields
AS
SELECT
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  t.kind,
  t.production_id,
  t.version_key,
  e.f_code,
  e.f_name,
  e.f_type,
  f.f_value
FROM
  sepo_tech_processes t,
  sepo_tp_fields f,
  sepo_tp_entities e
WHERE
    f.id_tp = t.id
  AND
    f.id_field = e.id;

CREATE TABLE sepo_tp_comments (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  comment_ CLOB,
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_comments
BEFORE INSERT ON sepo_tp_comments
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_opers;

CREATE TABLE sepo_tp_opers (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL REFERENCES sepo_tech_processes(id),
  key_ NUMBER NOT NULL,
  reckey NUMBER,
  order_ NUMBER,
  date_ VARCHAR2(50),
  num VARCHAR2(50) NOT NULL,
  place NUMBER,
  tpkey NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_opers
BEFORE INSERT ON sepo_tp_opers
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_opers.NEXTVAL;
END;
/

ALTER TABLE sepo_tp_opers MODIFY num VARCHAR2(50) NULL;

CREATE SEQUENCE sq_sepo_tp_oper_fields;

CREATE TABLE sepo_tp_oper_fields (
  id NUMBER PRIMARY KEY,
  id_oper NUMBER NOT NULL, -- REFERENCES sepo_tp_opers(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(4000),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_oper_fields
BEFORE INSERT ON sepo_tp_oper_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_oper_fields.NEXTVAL;
END;
/

CREATE TABLE sepo_tp_oper_comments (
  id NUMBER PRIMARY KEY,
  id_oper NUMBER NOT NULL, -- REFERENCES sepo_tp_opers(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  comment_ CLOB,
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_oper_comments
BEFORE INSERT ON sepo_tp_oper_comments
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_oper_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_steps;

CREATE TABLE sepo_tp_steps (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_op NUMBER NULL, -- REFERENCES sepo_tp_opers(id),
  key_ NUMBER NOT NULL,
  reckey NUMBER,
  order_ NUMBER,
  date_ VARCHAR2(50),
  num VARCHAR2(50) NOT NULL,
  operkey NUMBER NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_steps
BEFORE INSERT ON sepo_tp_steps
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_steps.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_step_fields;

CREATE TABLE sepo_tp_step_fields (
  id NUMBER PRIMARY KEY,
  id_step NUMBER NOT NULL, -- REFERENCES sepo_tp_steps(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(4000),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_step_fields
BEFORE INSERT ON sepo_tp_step_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_step_fields.NEXTVAL;
END;
/

CREATE TABLE sepo_tp_step_comments (
  id NUMBER PRIMARY KEY,
  id_step NUMBER NOT NULL, -- REFERENCES sepo_tp_steps(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  comment_ CLOB,
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_step_comments
BEFORE INSERT ON sepo_tp_step_comments
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_step_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_workers;

CREATE TABLE sepo_tp_workers (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_op NUMBER NULL, -- REFERENCES sepo_tp_opers(id),
  id_step NUMBER NULL, -- REFERENCES sepo_tp_steps(id),
  key_ NUMBER NOT NULL,
  reckey NUMBER,
  tblkey NUMBER,
  order_ NUMBER,
  date_ VARCHAR2(50),
  kind NUMBER,
  count_ NUMBER,
  operkey NUMBER,
  perehkey NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_workers
BEFORE INSERT ON sepo_tp_workers
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_workers.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_worker_fields;

CREATE TABLE sepo_tp_worker_fields (
  id NUMBER PRIMARY KEY,
  id_worker NUMBER NOT NULL, -- REFERENCES sepo_tp_workers(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(4000),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_worker_fields
BEFORE INSERT ON sepo_tp_worker_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_worker_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_equipments;

CREATE TABLE sepo_tp_equipments (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_op NUMBER NULL, -- REFERENCES sepo_tp_opers(id),
  id_step NUMBER NULL, -- REFERENCES sepo_tp_steps(id),
  key_ NUMBER NOT NULL,
  reckey NUMBER,
  order_ NUMBER,
  invnom NUMBER,
  date_ VARCHAR2(50),
  operkey NUMBER,
  perehkey NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_equipments
BEFORE INSERT ON sepo_tp_equipments
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_equipments.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_equipment_fields;

CREATE TABLE sepo_tp_equipment_fields (
  id NUMBER PRIMARY KEY,
  id_equipment NUMBER NOT NULL, -- REFERENCES sepo_tp_equipments(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(4000),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_equipment_fields
BEFORE INSERT ON sepo_tp_equipment_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_equipment_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_tools;

CREATE TABLE sepo_tp_tools (
  id NUMBER PRIMARY KEY,
  id_tp NUMBER NOT NULL, -- REFERENCES sepo_tech_processes(id),
  id_op NUMBER NULL, -- REFERENCES sepo_tp_opers(id),
  id_step NUMBER NULL, -- REFERENCES sepo_tp_steps(id),
  key_ NUMBER NOT NULL,
  reckey NUMBER,
  tblkey NUMBER,
  order_ NUMBER,
  date_ VARCHAR2(50),
  kind NUMBER,
  count_ NUMBER,
  operkey NUMBER,
  perehkey NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_tools
BEFORE INSERT ON sepo_tp_tools
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_tools.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tp_tool_fields;

CREATE TABLE sepo_tp_tool_fields (
  id NUMBER PRIMARY KEY,
  id_tool NUMBER NOT NULL, -- REFERENCES sepo_tp_tools(id),
  id_field NUMBER NULL, -- REFERENCES sepo_tp_entities(id),
  f_value VARCHAR2(4000),
  field_name VARCHAR2(200) NOT NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tp_tool_fields
BEFORE INSERT ON sepo_tp_tool_fields
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tp_tool_fields.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_import_log;

CREATE TABLE sepo_import_log (
  id NUMBER PRIMARY KEY,
  msg VARCHAR2(500) NOT NULL,
  date_ DATE DEFAULT SYSDATE
);

CREATE OR REPLACE TRIGGER tbi_sepo_import_log
BEFORE INSERT ON sepo_import_log
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_import_log.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_std_formulas;

CREATE TABLE sepo_std_formulas (
  id NUMBER PRIMARY KEY,
  id_record NUMBER NOT NULL REFERENCES sepo_std_table_records(id),
  id_field NUMBER NOT NULL REFERENCES sepo_std_table_fields(id),
  id_tool NUMBER NULL,
  field_value VARCHAR2(1000) NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_formulas
BEFORE INSERT ON sepo_std_formulas
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_formulas.NEXTVAL;
END;
/

CREATE TABLE sepo_std_tp_params (
  id_record NUMBER NOT NULL REFERENCES sepo_std_table_records(id),
  id_field NUMBER NOT NULL REFERENCES sepo_std_table_fields(id),
  param VARCHAR2(100) NOT NULL
);

CREATE GLOBAL TEMPORARY TABLE sepo_std_formulas_temp (
  id_record NUMBER,
  id_field NUMBER,
  field_value VARCHAR2(1000),
  cnt_tpparams NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_std_tp_params_temp (
  id_record NUMBER,
  id_field NUMBER,
  id_tool NUMBER,
  param VARCHAR2(100),
  value_ VARCHAR2(4000)
) ON COMMIT PRESERVE ROWS;

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
  f.f_value AS reckey,
  t.tblkey
FROM
  sepo_tp_tools t
  left JOIN
  sepo_tp_tool_fields f
  ON
    f.id_tool = t.id
  AND
    f.field_name = 'OsRc';

CREATE OR REPLACE VIEW v_sepo_std_tp_params
AS
SELECT
  p.id_record,
  p.id_field,
  p.param,
  pr.f_key AS reckey,
  r.f_key AS tblkey,
  ent.id AS id_ent,
  ent.f_code,
  ent.f_name
FROM
  sepo_std_tp_params p,
  sepo_std_table_records r,
  sepo_std_records pr,
  sepo_tp_entities ent
WHERE
    p.id_record = r.id
  AND
    pr.id_table = r.id_table
  AND
    regexp_replace(p.param, '\[|\]', '') = ent.f_code(+);

CREATE OR REPLACE VIEW v_sepo_std_tp_params_link
AS
SELECT
  p.id_record,
  p.id_field,
  tf.f_longname,
  tf.f_data,
  p.param,
  p.f_code,
  p.reckey,
  p.tblkey,
  t.catalog,
  t.id AS id_tool,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_ AS toolkey,
  t.order_,
  t.date_,
  t.kind,
  t.count_ AS tool_cnt,
  f.f_value
FROM
  v_sepo_std_tp_params p
  JOIN
  sepo_std_table_fields tf
  ON
      p.id_field = tf.id
  left JOIN
  v_sepo_tp_tools t
  ON
      p.reckey = t.reckey
    AND
      p.tblkey = t.tblkey
  left JOIN
  sepo_tp_tool_fields f
  ON
      f.id_tool = t.id
    AND
      f.field_name = p.f_code;

CREATE OR REPLACE VIEW v_sepo_std_dop_data
AS
SELECT
  g.id_record,
  n.field_value AS name,
  v.field_value AS sign_vo
FROM
  (
  SELECT
    fr.id_record,
    coalesce(fr.id_tool, -1) AS id_tool
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Полное наименование',
        'Обозначение для ВО'
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
    sepo_std_formulas fr,
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
GROUP BY
  g.id_record,
  n.field_value,
  v.field_value;

CREATE OR REPLACE VIEW v_sepo_std_folders
AS
WITH tr(lvl, lvl_2, child, parent)
AS
(
  SELECT
    f_level AS lvl,
    f_level AS lvl_2,
    f_level AS child,
    f_owner AS parent
  FROM
    sepo_std_folders

  UNION ALL

  SELECT
    tr.lvl,
    tr.child,
    f.f_level,
    f.f_owner
  FROM
    tr,
    sepo_std_folders f
  WHERE
      f.f_level = tr.parent
)
SELECT
  lvl AS lvl,
  lvl_2 AS lvl_type,
  child AS lvl_classify,
  parent
FROM
  tr
WHERE
    parent = 0;

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  13, 18, 'tia_bo_production_history_row'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  14, 18, 'tia_bo_production_history_st'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  15, 18, 'tia_konstrobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  16, 18, 'taiur_konstrobj_sosign'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  17, 18, 'taiud_konstrobj_sosign'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  18, 18, 'tbiu_stockobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  19, 18, 'tib_stockobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  20, 18, 'taiur_stockobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  21, 18, 'taiud_stockobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  22, 18, 'tiua_businessobj_promotion_row'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  23, 18, 'tiua_businessobj_promotion'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  24, 18, 'tbi_sepo_konstrobj'
);

INSERT INTO sepo_import_triggers_disable (
  id, id_task, trigger_name
)
VALUES (
  25, 18, 'tia_standarts'
);

CREATE GLOBAL TEMPORARY TABLE sepo_std_attrs_temp (
  id_record NUMBER,
  attr_name VARCHAR2(100),
  attr_type NUMBER,
  attr_value VARCHAR2(1000),
  enum_code NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE TABLE sepo_std_import_settings (
  enum_relative VARCHAR2(20),
  attr_relative VARCHAR2(20),
  group_name VARCHAR2(20),
  default_scheme VARCHAR2(100)
);

INSERT INTO sepo_std_import_settings (
  enum_relative, attr_relative, group_name,
  default_scheme
)
VALUES (
  '@Тип_оснастки', '@Тип_оснастки', 'Стандартная',
  'Выбор схемы атрибутов для стандартной оснастки'
);

CREATE GLOBAL TEMPORARY TABLE sepo_std_tech_attrs_temp (
  fixcode NUMBER,
  reckey NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE VIEW v_sepo_std_gosts
AS
SELECT
  r.id AS id_record,
--  f.field,
--  f.f_longname,
--  f.f_entermode,
  REPLACE(
    CASE
      WHEN f.f_entermode = 'IEM_ASPARENT' THEN
        coalesce(c.field_value, pc.field_value)
      ELSE
        c.field_value
    END,
    '~',
    ' '
  ) AS gost
--  c.field_value,
--  pc.field_value
FROM
  sepo_std_table_records r
  left JOIN
  sepo_std_table_fields f
  ON
      f.id_table = r.id_table
    AND
      f.f_longname = 'ОБОЗНАЧЕНИЕ СТАНДАРТА'
  left JOIN
  sepo_std_table_rec_contents c
  ON
      c.id_record = r.id
    AND
      c.id_field = f.id
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = r.id_table
  JOIN
  sepo_std_fields pf
  ON
    pf.f_longname = 'ОБОЗНАЧЕНИЕ СТАНДАРТА'
  left JOIN
  sepo_std_record_contents pc
  ON
      pc.id_record = pr.id
    AND
      pc.id_field = pf.id;

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
  d.name,
  d.sign_vo,
  sh.omp_name AS scheme_name,
  g.gost
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
  v_sepo_std_dop_data d
  ON
    r.id = d.id_record
  JOIN
  v_sepo_std_gosts g
  ON
    g.id_record = r.id
  JOIN
  v_sepo_std_schemes sh
  ON
      sh.id_record = pr.id;

CREATE SEQUENCE sq_sepo_std_foxpro_attrs;

CREATE TABLE sepo_std_foxpro_attrs (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(255) NOT NULL UNIQUE,
  shortname VARCHAR2(15) NOT NULL UNIQUE,
  type_ NUMBER NOT NULL,
  CHECK(type_ > 0 AND type_ < 5)
);

CREATE OR REPLACE TRIGGER tbi_sepo_std_foxpro_attrs
BEFORE INSERT ON sepo_std_foxpro_attrs
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_std_foxpro_attrs.NEXTVAL;
END;
/

CREATE GLOBAL TEMPORARY TABLE sepo_std_foxpro_attrs_temp (
  attrcode NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_std_scheme_attrs_temp (
  id_table NUMBER,
  attrcode NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_std_import_temp (
  id_record NUMBER,
  id_parent_record NUMBER,
  lvl_classify NUMBER,
  lvl_type NUMBER,
  f_level NUMBER,
  reckey NUMBER,
  tblkey NUMBER,
  f_table VARCHAR2(100),
  name VARCHAR2(200),
  sign_vo VARCHAR2(200),
  scheme_name VARCHAR2(100),
  gost VARCHAR2(100)
) ON COMMIT PRESERVE ROWS;

UPDATE omp_sepo_properties
SET
  property_value = '1.0.0.101'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2018_06_05_v1'
WHERE
    id = 2;