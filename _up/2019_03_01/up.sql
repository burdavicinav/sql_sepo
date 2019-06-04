SPOOL log.txt

-- 2019_01_13_v1 -> 2019_03_01_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2019_01_13_v1' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;

END;
/

INSERT INTO sepo_task_list (
  id, name, id_folder
)
VALUES (
  25, 'Загруженная оснастка', 2
);

ALTER TABLE sepo_osn_all ADD file_isload NUMBER DEFAULT 1 NOT NULL CHECK(file_isload IN (0,1));

CREATE OR REPLACE VIEW v_sepo_fixture_docs
AS
SELECT
  l.art_id,
  l.bocode,
  a.doc_id,
  d.filename,
  bo.name,
  bo.revision,
  bo.today_state,
  bs.name AS state,
  a.file_isload
FROM
  sepo_osn_all a
  JOIN
  v_sepo_search_omega_link l
  ON
      l.art_id = a.art_id
  JOIN
  sepo_osn_docs d
  ON
      d.doc_id = a.doc_id
  JOIN
  business_objects bo
  ON
      bo.code = l.bocode
  JOIN
  businessobj_states bs
  ON
      bs.code = bo.today_state
WHERE
    a.doc_id != -2
GROUP BY
  l.art_id,
  l.bocode,
  a.doc_id,
  d.filename,
  bo.name,
  bo.revision,
  bo.today_state,
  bs.name,
  a.file_isload;

UPDATE omp_sepo_properties
SET
  property_value = '2.0.7000.209'
WHERE
    id = 1;

UPDATE omp_sepo_properties
SET
  property_value = '2019_03_01_v1'
WHERE
    id = 2;

COMMIT;