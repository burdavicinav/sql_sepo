SPOOL log.txt

-- 2018_12_11_v1 -> 2019_01_13_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_12_11_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

INSERT INTO sepo_task_folder_list (
  id, name
)
VALUES (
  6, 'Файлы'
);

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  24, 'Расчет хэша', 6
);

SELECT * FROM omp_sepo_properties;

UPDATE omp_sepo_properties
SET
  property_value = '2.0.6952.35000'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_01_13_v1'
WHERE
    id = 2;