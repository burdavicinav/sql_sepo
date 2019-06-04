SPOOL log.txt

-- 2019_03_01_v1 -> 2019_03_17_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2019_03_01_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

CREATE TABLE sepo_tflex_obj_parameters (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100) UNIQUE NOT NULL
);

INSERT INTO sepo_tflex_obj_parameters (
  id, name
)
VALUES (
  1, 'Обозначение'
);

ALTER TABLE sepo_tflex_obj_synch ADD
  param_dependence NUMBER DEFAULT 0 NOT NULL  CHECK (param_dependence IN (0,1));

ALTER TABLE sepo_tflex_obj_synch ADD
  id_param NUMBER NULL REFERENCES sepo_tflex_obj_parameters(id);

ALTER TABLE sepo_tflex_obj_synch ADD expression VARCHAR2(100) NULL;

CREATE TABLE sepo_tflex_parameters (
  fixtype_default NUMBER,
  fixtype_manual NUMBER DEFAULT 0 NOT NULL CHECK (fixtype_manual IN (0,1))
);

INSERT INTO sepo_tflex_parameters (
  fixtype_default, fixtype_manual
)
VALUES (
  NULL, 1
);

CREATE OR REPLACE VIEW v_sepo_tflex_bo_types (
  botype,
  botypename,
  botypeshortname
) AS
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
    kt.code IN (0, 2, 6, 20, 22, 31, 32);

BEGIN
  FOR i IN (
    SELECT
      constraint_name
    FROM
      dba_constraints
    WHERE
        table_name = 'SEPO_TFLEX_OBJ_SYNCH'
      AND
        constraint_type = 'U'

  ) LOOP
    EXECUTE IMMEDIATE 'alter table sepo_tflex_obj_synch drop constraint '
      || i.constraint_name;

  END LOOP;

END;

ALTER TABLE sepo_tflex_obj_synch ADD UNIQUE (tflex_section, tflex_docsign, omp_botype);

CREATE OR REPLACE VIEW v_sepo_tflex_obj_synch (
  id,
  id_section,
  tflex_section,
  id_docsign,
  tflex_docsign,
  kotype,
  botype,
  botypename,
  botypeshortname,
  bostatecode,
  bostatename,
  bostateshortname,
  filegroup,
  filegroupname,
  filegroupshortname,
  owner,
  ownername,
  ompsection,
  ompsectionname,
  param_dependence,
  id_param,
  param,
  param_expression
) AS
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
  os.name AS ompsectionname,
  sh.param_dependence,
  sh.id_param,
  p.name AS param,
  sh.expression
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
      os.code = sh.omp_section
  left JOIN
  sepo_tflex_obj_parameters p
  ON
      p.id = sh.id_param;

CREATE SEQUENCE sq_sepo_tflex_fixture_log;

CREATE TABLE sepo_tflex_fixture_log (
  id NUMBER PRIMARY KEY,
  date_ DATE NOT NULL,
  timespan VARCHAR2(50) NULL,
  loginname VARCHAR2(100) NULL,
  machine VARCHAR2(100) NULL,
  doc VARCHAR2(1000) NULL,
  tflex_section VARCHAR2(100) NULL,
  tflex_position VARCHAR2(10) NULL,
  tflex_sign VARCHAR2(100) NULL,
  tflex_name VARCHAR2(1000) NULL,
  tflex_qty NUMBER NULL,
  tflex_doccode VARCHAR2(100) NULL,
  tflex_filepath VARCHAR2(1000) NULL,
  omp_type NUMBER NULL,
  log_ CLOB NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_tflex_fixture_log
BEFORE INSERT ON sepo_tflex_fixture_log
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_tflex_fixture_log.NEXTVAL;
END;
/

CREATE OR REPLACE PROCEDURE p_sepo_tflex_fixture_log (
  p_date DATE,
  p_timespan VARCHAR2,
  p_loginname VARCHAR2,
  p_machine VARCHAR2,
  p_doc VARCHAR2,
  p_section VARCHAR2,
  p_position VARCHAR2,
  p_sign VARCHAR2,
  p_name VARCHAR2,
  p_qty NUMBER,
  p_doccode VARCHAR2,
  p_filepath VARCHAR2,
  p_omptype NUMBER,
  p_log CLOB
)
IS
BEGIN
  INSERT INTO sepo_tflex_fixture_log (
    date_, timespan, loginname, machine, doc, tflex_section, tflex_position,
    tflex_sign, tflex_name, tflex_qty, tflex_doccode, tflex_filepath,
    log_
  )
  VALUES (
    p_date, p_timespan, p_loginname, p_machine, p_doc, p_section, p_position,
    p_sign, p_name, p_qty, p_doccode, p_filepath,
    p_log
  );

END;
/

GRANT EXECUTE ON omp_adm.p_sepo_tflex_fixture_log TO tflex_user;

GRANT SELECT ON omp_adm.fixture_types TO tflex_user;

CREATE TABLE sepo_tflex_alt_code_list (
  id NUMBER PRIMARY KEY,
  code VARCHAR2(10) NOT NULL UNIQUE,
  value_ VARCHAR2(100)
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  1, '042', 'x'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  2, 'S', ' '
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  3, 'c', 'd'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  4, 'd', 'гр'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  5, 'p', '+-'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  6, 'u', ''
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  7, 'o', ''
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  8, 'r', ''
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  9, '043', '+'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  10, '-', '-'
);

INSERT INTO sepo_tflex_alt_code_list (
  id, code, value_
)
VALUES (
  11, '066', 'd'
);

UPDATE omp_sepo_properties
SET
  property_value = '2.0.7015.41981'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_03_17_v1'
WHERE
    id = 2;

COMMIT;