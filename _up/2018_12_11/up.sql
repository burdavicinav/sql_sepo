SPOOL log.txt

-- 2018_11_11_v1 -> 2018_12_11_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_11_11_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

INSERT INTO sepo_task_folder_list (
  id, name, id_parent
)
VALUES (
  5, 'TFlex', 2
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  21, 'Разделы спецификаций', 5
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  22, 'Обозначения документов', 5
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  23, 'Синхронизация объектов', 5
);

CREATE SEQUENCE sq_sepo_tflex_spec_sections;

CREATE TABLE sepo_tflex_spec_sections (
  id NUMBER PRIMARY KEY,
  section_ VARCHAR2(100) NOT NULL UNIQUE
);

CREATE OR REPLACE TRIGGER tbi_sepo_tflex_spec_sections
BEFORE INSERT ON sepo_tflex_spec_sections
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tflex_spec_sections.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tflex_sign_docs;

CREATE TABLE sepo_tflex_sign_docs(
  id NUMBER PRIMARY KEY,
  Sign VARCHAR2(100) NOT NULL UNIQUE
);

CREATE OR REPLACE TRIGGER tbi_sepo_tflex_sign_docs
BEFORE INSERT ON sepo_tflex_sign_docs
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tflex_sign_docs.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tflex_obj_synch;

CREATE TABLE sepo_tflex_obj_synch(
  id NUMBER PRIMARY KEY,
  tflex_section NUMBER NOT NULL REFERENCES sepo_tflex_spec_sections(id),
  tflex_docsign NUMBER NULL REFERENCES sepo_tflex_sign_docs(id),
  omp_botype NUMBER NOT NULL,
  omp_bostate NUMBER NOT NULL,
  omp_filegroup NUMBER NULL,
  omp_owner NUMBER NULL,
  omp_section NUMBER NOT NULL,

  UNIQUE(tflex_section, tflex_docsign)
);

CREATE OR REPLACE TRIGGER tbi_sepo_tflex_obj_synch
BEFORE INSERT ON sepo_tflex_obj_synch
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tflex_obj_synch.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_tflex_obj_synch
AS
SELECT
  sh.id,
  sc.id AS id_section,
  sc.section_ AS tflex_section,
  sd.id AS id_docsign,
  sd.Sign AS tflex_docsign,
  btl.kotype,
  bt.code AS botype,
  bt.name AS botypename,
  bt.shortname AS botypeshortname,
  bs.code AS bostatecode,
  bs.name AS bostatename,
  bs.shortname AS bostateshortname,
  ag.code AS filegroup,
  ag.name AS filegroupname,
  ag.shortname AS filegroupshortname,
  ow.owner,
  ow.name AS ownername,
  os.code AS ompsection,
  os.name AS ompsectionname
FROM
  sepo_tflex_obj_synch sh
  JOIN
  sepo_tflex_spec_sections sc
  ON
      sc.id = sh.tflex_section
  left JOIN
  sepo_tflex_sign_docs sd
  ON
      sd.id = sh.tflex_docsign
  JOIN
  businessobj_types bt
  ON
      bt.code = sh.omp_botype
  JOIN
  kotype_to_botype btl
  ON
      btl.botype = bt.code
  JOIN
  businessobj_states bs
  ON
      bs.code = sh.omp_bostate
  left JOIN
  attachments_groups ag
  ON
      ag.code = sh.omp_filegroup
  left JOIN
  owner_name ow
  ON
      ow.owner = sh.omp_owner
  JOIN
  spc_sections os
  ON
      os.code = sh.omp_section;

INSERT INTO sepo_tflex_spec_sections (section_) VALUES ('Сборочные единицы');
INSERT INTO sepo_tflex_spec_sections (section_) VALUES ('Комплекты');
INSERT INTO sepo_tflex_spec_sections (section_) VALUES ('Документация');
INSERT INTO sepo_tflex_spec_sections (section_) VALUES ('Детали');

INSERT INTO sepo_tflex_sign_docs (Sign) VALUES ('СБ');
INSERT INTO sepo_tflex_sign_docs (Sign) VALUES ('Э');

CREATE OR REPLACE VIEW v_sepo_tflex_bo_types
AS
SELECT
  bt.code AS botype,
  bt.name AS botypename,
  bt.shortname AS botypeshortname
FROM
  ko_types kt
  JOIN
  kotype_to_botype ktb
  ON
      ktb.kotype = kt.code
  JOIN
  businessobj_types bt
  ON
      bt.code = ktb.botype
WHERE
    kt.code IN (0, 2, 6, 20, 31);

GRANT SELECT ON v_sepo_tflex_obj_synch TO tflex_user;