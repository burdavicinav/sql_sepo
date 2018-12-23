create table sepo_task_folder_list (
  id number primary key,
  name varchar2(100) not null,
  id_parent number null references sepo_task_folder_list(id)
);

create table sepo_task_list (
  id number primary key,
  name varchar2(100) not null,
  id_folder number not null references sepo_task_folder_list(id)
);

insert into sepo_task_folder_list
(id, name, id_parent)
values
(1, 'Импорт/Экспорт', null);

insert into sepo_task_folder_list
(id, name, id_parent)
values
(2, 'Тест', 1);

insert into sepo_task_folder_list
(id, name, id_parent)
values
(3, 'Тест2', 2);

insert into sepo_task_list
(id, name, id_folder)
values
(1, 'Импорт профессий', 1);

insert into sepo_task_list
(id, name, id_folder)
values
(2, 'Импорт технологических операций', 1);

insert into sepo_task_list
(id, name, id_folder)
values
(3, 'Импорт технологических переходов', 1);

insert into sepo_task_list
(id, name, id_folder)
values
(4, 'Импорт моделей оборудования', 1);

insert into sepo_task_list
(id, name, id_folder)
values
(5, 'Импорт оснастки', 1);

insert into sepo_task_list
(id, name, id_folder)
values
(6, 'Экспорт профессий', 1);

CREATE SEQUENCE sq_sepo_professions;

CREATE TABLE sepo_professions (
  id NUMBER PRIMARY KEY,
  prof_code NUMBER,
  prof_name VARCHAR2(121)
);

CREATE OR REPLACE TRIGGER tbi_sepo_professions
BEFORE INSERT ON sepo_professions
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_professions.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_oper_folders;

CREATE TABLE sepo_oper_folders (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_owner NUMBER,
  f_level NUMBER,
  f_name VARCHAR2(255),
  f_sort VARCHAR2(15),
  f_mask VARCHAR2(15),
  f_tag1 VARCHAR2(15),
  f_tag2 VARCHAR2(15),
  f_textid VARCHAR2(10),
  f_graphid VARCHAR2(15),
  f_created VARCHAR2(121),
  f_user VARCHAR2(50),
  f_tag3 VARCHAR2(15),
  f_tag4 VARCHAR2(15)
);

CREATE OR REPLACE TRIGGER tbi_sepo_oper_folders
BEFORE INSERT ON sepo_oper_folders
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_oper_folders.NEXTVAL;
END;
/

CREATE TABLE sepo_oper_folder_codes (
  f_level NUMBER,
  f_code VARCHAR2(15)
);

CREATE SEQUENCE sq_sepo_oper_recs;

CREATE TABLE sepo_oper_recs (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_level NUMBER,
  f1 VARCHAR2(50),
  f2 VARCHAR2(50),
  f3 VARCHAR2(50),
  f4 VARCHAR2(50),
  suf_code VARCHAR2(10)
);

CREATE OR REPLACE TRIGGER tbi_sepo_oper_recs
BEFORE INSERT ON sepo_oper_recs
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_oper_recs.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_operations
AS
SELECT
  o.id,
  o.f_owner,
  o.f_level,
  o.f_name,
  o.f_sort,
  r.id AS id_rec,
  r.f1,
  r.f2,
  r.f3,
  r.f4,
  r.suf_code
FROM
  (
  SELECT
    *
  FROM
    sepo_oper_folders p
  WHERE
      NOT EXISTS (
        SELECT 1 FROM sepo_oper_folders c
        WHERE
            c.f_owner = p.f_level
      )
  ) o
  left JOIN
  sepo_oper_recs r
  ON
      o.f_level = r.f_level * (-1);

CREATE SEQUENCE sq_sepo_professions_on_opers;

CREATE TABLE sepo_professions_on_opers (
  id NUMBER PRIMARY KEY,
  id_oper NUMBER NOT NULL REFERENCES sepo_oper_recs(id),
  id_prof NUMBER NOT NULL REFERENCES sepo_professions(id),
  UNIQUE (id_oper, id_prof)
);

CREATE OR REPLACE TRIGGER tbi_sepo_professions_on_opers
BEFORE INSERT ON sepo_professions_on_opers
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_professions_on_opers.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tech_steps;

CREATE TABLE sepo_tech_steps (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_owner NUMBER,
  f_level NUMBER,
  f_name VARCHAR2(255)
);

CREATE OR REPLACE TRIGGER tbi_sepo_tech_steps
BEFORE INSERT ON sepo_tech_steps
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tech_steps.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_tech_step_texts;

CREATE TABLE sepo_tech_step_texts (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_level NUMBER,
  f_type VARCHAR2(255),
  f_numbered VARCHAR2(255),
  f_name VARCHAR2(255),
  f_blob CLOB
);

CREATE OR REPLACE TRIGGER tbi_sepo_tech_step_texts
BEFORE INSERT ON sepo_tech_step_texts
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tech_step_texts.NEXTVAL;
END;
/

CREATE GLOBAL TEMPORARY TABLE sepo_tech_steps_tree (
  parent NUMBER,
  child NUMBER,
  name VARCHAR2(200),
  is_step NUMBER,
  path VARCHAR2(4000),
  step_path VARCHAR2(4000),
  level_ NUMBER,
  order_ NUMBER,
  blob_ VARCHAR2(4000)
) ON COMMIT PRESERVE ROWS;

CREATE SEQUENCE sq_sepo_eqp_model_folders;

CREATE TABLE sepo_eqp_model_folders (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_owner NUMBER,
  f_level NUMBER,
  f_name VARCHAR2(255)
);

CREATE OR REPLACE TRIGGER tbi_sepo_eqp_model_folders
BEFORE INSERT ON sepo_eqp_model_folders
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_eqp_model_folders.NEXTVAL;
END;
/

CREATE SEQUENCE sq_sepo_eqp_model_records;

CREATE TABLE sepo_eqp_model_records (
  id NUMBER PRIMARY KEY,
  f_key NUMBER,
  f_level NUMBER,
  f1 VARCHAR2(255),
  f2 VARCHAR2(255),
  f3 VARCHAR2(255),
  f4 VARCHAR2(255),
  f5 VARCHAR2(255),
  f6 VARCHAR2(255),
  f7 VARCHAR2(255),
  f8 VARCHAR2(255),
  f9 VARCHAR2(255),
  f10 VARCHAR2(255),
  f11 VARCHAR2(255)
);

CREATE OR REPLACE TRIGGER tbi_sepo_eqp_model_records
BEFORE INSERT ON sepo_eqp_model_records
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_eqp_model_records.NEXTVAL;
END;
/

CREATE GLOBAL TEMPORARY TABLE sepo_integer_table (
  numb NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE VIEW v_sepo_eqp_models
AS
SELECT
  f.id AS id_folder,
  f.f_key,
  f.f_owner,
  f.f_level,
  f.f_name,
  r.id AS id_record,
  r.f1,
  r.f2,
  r.f3,
  r.f4,
  r.f5,
  r.f6,
  r.f7,
  r.f8,
  r.f9,
  r.f10,
  r.f11
FROM
  sepo_eqp_model_folders f
  left JOIN
  sepo_eqp_model_records r
  ON
      f.f_level = r.f_level * (-1)
WHERE
    NOT EXISTS (
      SELECT 1 FROM sepo_eqp_model_folders f_
      WHERE
          f.f_level = f_.f_owner
    )
ORDER BY
  f.f_name;

CREATE OR REPLACE VIEW v_sepo_eqp_models_unique
AS
SELECT
  m.*,
  fd.f_name AS unique_name,
  fd.cnt_recs
FROM
  v_sepo_eqp_models m,
  (
  SELECT
    Min(f_key) AS f_key,
    Min(f_level) AS f_level,
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', 'ЕТОРАНКХСВМ') AS f_name,
    Count(DISTINCT id) AS cnt_recs
  FROM
    sepo_eqp_model_folders
  GROUP BY
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', 'ЕТОРАНКХСВМ')
  ) fd
WHERE
    m.f_key = fd.f_key;

CREATE SEQUENCE sq_sepo_osn_all;

CREATE TABLE sepo_osn_all (
  id NUMBER PRIMARY KEY,
  art_id NUMBER,
  doc_id NUMBER,
  isp_code NUMBER,
  designatio VARCHAR2(100),
  name VARCHAR2(200),
  okp_code NUMBER,
  imbase_key VARCHAR2(100),
  purchased VARCHAR2(100),
  massa NUMBER,
  mu_id NUMBER,
  section_id NUMBER,
  note VARCHAR2(100),
  expanding VARCHAR2(100),
  litera VARCHAR2(100),
  mmr VARCHAR2(100),
  art_ver_id NUMBER,
  author VARCHAR2(100),
  chkindate VARCHAR2(100),
  pr_id NUMBER,
  need_svo VARCHAR2(100),
  modifdate VARCHAR2(100),
  modifuser_id NUMBER,
  baseart_id NUMBER,
  art_class NUMBER,
  serial_no VARCHAR2(100),
  set_no VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER tbi_sepo_osn_all
BEFORE INSERT ON sepo_osn_all
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_osn_all.NEXTVAL;
END;
/