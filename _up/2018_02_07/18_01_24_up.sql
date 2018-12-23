ALTER TABLE sepo_osn_all RENAME COLUMN designatio TO designation;

CREATE SEQUENCE sq_sepo_osn_det;

CREATE TABLE sepo_osn_det (
  id NUMBER PRIMARY KEY,
  art_id NUMBER,
  s_material VARCHAR2(200),
  dce VARCHAR2(100),
  izd VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_det
BEFORE INSERT ON sepo_osn_det
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_all.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_osn_docs;

CREATE TABLE sepo_osn_docs (
  id NUMBER PRIMARY KEY,
  doc_id NUMBER,
  archive_id NUMBER,
  filename VARCHAR2(100),
  arc_dir_id NUMBER,
  wrk_dir_id NUMBER,
  designatio VARCHAR2(100),
  name VARCHAR2(200),
  format VARCHAR2(100),
  designerid NUMBER,
  doc_type NUMBER,
  doc_status NUMBER,
  revision NUMBER,
  note VARCHAR2(100),
  version_id NUMBER,
  createdate VARCHAR2(30),
  modifydate VARCHAR2(30),
  modifyuser_id NUMBER,
  otd_status VARCHAR2(100),
  otd_reg VARCHAR2(100),
  otd_annul VARCHAR2(100),
  otd_reg_user VARCHAR2(100),
  otd_annul_user VARCHAR2(100),
  canc_status VARCHAR2(100),
  invisible NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_docs
BEFORE INSERT ON sepo_osn_docs
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_docs.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_osn_se;

CREATE TABLE sepo_osn_se (
  id NUMBER PRIMARY KEY,
  art_id NUMBER,
  s_material VARCHAR2(100),
  naim_dse VARCHAR2(100),
  field1 VARCHAR2(100),
  field3 VARCHAR2(100),
  field2 VARCHAR2(100),
  dce VARCHAR2(100),
  izd VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_se
BEFORE INSERT ON sepo_osn_se
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_se.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_osn_sostav;

CREATE TABLE sepo_osn_sostav (
  id NUMBER PRIMARY KEY,
  prjlink_id NUMBER,
  proj_aid NUMBER,
  part_aid NUMBER,
  count_pc NUMBER,
  mu_id NUMBER,
  razdel NUMBER,
  position NUMBER,
  note VARCHAR2(100),
  variants VARCHAR2(100),
  link_type VARCHAR2(100),
  format VARCHAR2(100),
  pr_id NUMBER,
  f_start_dt VARCHAR2(100),
  f_finish_dt VARCHAR2(100),
  order_id NUMBER,
  ctx_id NUMBER,
  ctx_fl VARCHAR2(100),
  opt_link VARCHAR2(100),
  author NUMBER,
  proj_ver_id NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_sostav
BEFORE INSERT ON sepo_osn_sostav
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_sostav.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_osn_sp;

CREATE TABLE sepo_osn_sp (
  id NUMBER PRIMARY KEY,
  art_id NUMBER,
  s_material VARCHAR2(100),
  field1 VARCHAR2(100),
  field2 VARCHAR2(200),
  field3 VARCHAR2(100),
  dce VARCHAR2(100),
  izd VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_sp
BEFORE INSERT ON sepo_osn_sp
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_sp.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_osn_se_sp
AS
SELECT
  art_id,
  Max(field3) AS osn_type,
  Max(type_sign) AS type_sign
FROM
  (
  SELECT
    art_id,
    field3,
    SubStr(field3, 1, 1) AS type_sign
  FROM
    sepo_osn_se

  UNION ALL

  SELECT
    art_id,
    field3,
    SubStr(field3, 1, 1) AS type_sign
  FROM
    sepo_osn_sp
  )
GROUP BY
  art_id;

CREATE SEQUENCE sq_sepo_osn_types;

CREATE TABLE sepo_osn_types (
  id NUMBER PRIMARY KEY,
  shortname VARCHAR2(100),
  id_type NUMBER REFERENCES fixture_types(code) ON DELETE SET NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_types
BEFORE INSERT ON sepo_osn_types
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_types.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_osn_types
AS
SELECT
  s.id,
  s.shortname,
  f.code AS omp_code,
  f.name AS omp_name
FROM
  sepo_osn_types s,
  fixture_types f
WHERE
    s.id_type = f.code(+);

CREATE OR REPLACE VIEW v_sepo_fixture_nodes_load
AS
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
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

CREATE OR REPLACE VIEW v_sepo_fixture_load
AS
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
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

CREATE OR REPLACE VIEW v_sepo_fixture_details_load
AS
SELECT
  a.id,
  a.art_id,
  a.doc_id,
  a.designation,
  a.name,
  a.section_id,
  a.chkindate,
  a.modifdate,
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
    EXISTS
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

-- удаление задачи импорта оснастки
DELETE FROM sepo_task_list
WHERE
    id = 5;

INSERT INTO sepo_task_folder_list
VALUES
(2, 'Импорт оснастки', 1);

INSERT INTO sepo_task_list
VALUES
(7, 'Загрузка данных из файлов', 2);

INSERT INTO sepo_task_list
VALUES
(8, 'Соответствие типов оснастки', 2);

INSERT INTO sepo_task_list
VALUES
(9, 'Импорт объектов', 2);

INSERT INTO sepo_task_list
VALUES
(10, 'Присоединенные файлы', 2);

CREATE TABLE sepo_import_types (
  id NUMBER PRIMARY KEY,
  import_name VARCHAR2(100) UNIQUE
);

INSERT INTO sepo_import_types
(id, import_name)
VALUES
(1, 'Импорт узлов оснастки');

INSERT INTO sepo_import_types
(id, import_name)
VALUES
(2, 'Импорт оснастки');

INSERT INTO sepo_import_types
(id, import_name)
VALUES
(3, 'Импорт деталей оснастки');

INSERT INTO sepo_import_types
(id, import_name)
VALUES
(4, 'Импорт состава оснастки');

CREATE SEQUENCE sq_sepo_import_logs;

CREATE TABLE sepo_import_logs (
  id NUMBER PRIMARY KEY,
  id_type NUMBER NOT NULL REFERENCES sepo_import_types(id),
  id_base NUMBER NULL,
  log_ VARCHAR2(4000)
);

CREATE OR REPLACE TRIGGER tbi_sepo_import_logs
BEFORE INSERT ON sepo_import_logs
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_import_logs.NEXTVAL;
END;
/

CREATE TABLE sepo_import_triggers_disable (
  id NUMBER PRIMARY KEY,
  id_task NUMBER REFERENCES sepo_task_list(id),
  trigger_name VARCHAR2(50) NOT NULL
);

INSERT INTO sepo_import_triggers_disable
VALUES
(1, 9, 'tia_bo_production_history_row');

INSERT INTO sepo_import_triggers_disable
VALUES
(2, 9, 'tia_bo_production_history_st');

INSERT INTO sepo_import_triggers_disable
VALUES
(3, 9, 'tia_konstrobj');

INSERT INTO sepo_import_triggers_disable
VALUES
(4, 9, 'taiur_konstrobj_sosign');

INSERT INTO sepo_import_triggers_disable
VALUES
(5, 9, 'taiud_konstrobj_sosign');

INSERT INTO sepo_import_triggers_disable
VALUES
(6, 9, 'tbiu_stockobj');

INSERT INTO sepo_import_triggers_disable
VALUES
(7, 9, 'tib_stockobj');

INSERT INTO sepo_import_triggers_disable
VALUES
(8, 9, 'taiur_stockobj');

INSERT INTO sepo_import_triggers_disable
VALUES
(9, 9, 'taiud_stockobj');

INSERT INTO sepo_import_triggers_disable
VALUES
(10, 9, 'tiua_businessobj_promotion_row');

INSERT INTO sepo_import_triggers_disable
VALUES
(11, 9, 'tiua_businessobj_promotion');

INSERT INTO sepo_import_triggers_disable
VALUES
(12, 9, 'tbi_sepo_konstrobj');

CREATE TABLE sepo_osn_docs_link_omp (
  id_doc NUMBER,
  id_omega_doc NUMBER
);

CREATE GLOBAL TEMPORARY TABLE sepo_attachment_groups_filter (
  botype NUMBER,
  grcode NUMBER
) ON COMMIT PRESERVE ROWS;