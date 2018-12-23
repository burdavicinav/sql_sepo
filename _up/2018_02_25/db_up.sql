-- 2018_02_07_v1 -> 2018_02_25_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_02_07_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  11, 'Импорт инструкций по ТБ', 1
);

CREATE SEQUENCE sq_sepo_instructions_tb;

CREATE TABLE sepo_instructions_tb (
  id NUMBER PRIMARY KEY,
  f_key NUMBER NOT NULL,
  f_name VARCHAR2(1000) NOT NULL,
  f_owner NUMBER,
  f_level NUMBER
);

CREATE OR REPLACE TRIGGER tbi_sepo_instructions_tb
BEFORE INSERT ON sepo_instructions_tb
FOR EACH ROW
WHEN (NEW.id IS NULL)
BEGIN
  :new.id := sq_sepo_instructions_tb.NEXTVAL;
END;
/

CREATE OR REPLACE VIEW v_sepo_split_instructions_tb
AS
WITH split(id_inst, numb, type_, str) AS (
SELECT
  id AS id_inst,
  1 AS numb,
  regexp_substr(f_name, '^\D+', 1, 1) AS type_,
  regexp_replace(f_name, ';', ',') AS str
FROM
  sepo_instructions_tb
UNION ALL
SELECT
  id_inst,
  numb + 1 AS n,
  type_,
  str
FROM
  split
WHERE
    InStr(str, ',', 1, numb) > 0
)
SELECT
  id,
  str,
  numb,
  type_,
  Trim(regexp_substr(str, '[^,]+', 1, numb)) AS instruction,
  i.f_key,
  i.f_level,
  i.f_owner
FROM
  split s,
  sepo_instructions_tb i
WHERE
    i.id = s.id_inst
ORDER BY
  id,
  numb;

CREATE OR REPLACE VIEW v_sepo_instructions_tb
AS
SELECT
  id,
  str,
  numb,
  type_,
  f_key,
  f_level,
  f_owner,
  CASE
    WHEN Trim(type_) = 'ИОТ №' AND NOT regexp_like(instruction, 'ИОТ №') THEN
      type_ || instruction
    ELSE instruction
  END AS instruction
FROM
  v_sepo_split_instructions_tb;

UPDATE omp_sepo_properties SET property_value = '1.0.0.3'
WHERE
    id = 1;

UPDATE omp_sepo_properties SET property_value = '2018_02_25_v1'
WHERE
    id = 2;