SELECT * FROM sepo_professions;

SELECT * FROM professions;

SELECT * FROM sepo_oper_folders;
SELECT * FROM sepo_oper_recs;
SELECT * FROM sepo_professions_on_opers;

SELECT * FROM technology_operations;

SELECT * FROM sepo_tech_steps;
SELECT * FROM sepo_tech_step_texts;

SELECT
  f_type,
  Count(DISTINCT id)
FROM
  sepo_tech_step_texts
GROUP BY
  f_type;

SELECT
  *
FROM
  sepo_tech_step_texts
WHERE
    f_type = 'OIT_Unknown';

SELECT * FROM sepo_tech_steps
WHERE
    f_level = 13900;

SELECT
  *
FROM
  sepo_tech_steps
WHERE
    f_name LIKE '%ÊËÀÑÑÈÔÈÊÀÒÎÐ%';

SELECT
  s.f_key,
  s.f_owner,
  s.f_level,
  s.f_name,
  t.f_key AS owner_key,
  t.f_level AS owner_level,
  t.f_type AS owner_type,
  t.f_numbered AS owner_numbered,
  t.f_blob AS owner_blob
FROM
  sepo_tech_steps s,
  sepo_tech_step_texts t
WHERE
    s.f_owner = t.f_level
  AND
    NOT EXISTS
    (
      SELECT 1 FROM sepo_tech_step_texts t_
      WHERE
          t_.f_level = s.f_level
    );

EXEC pkg_sepo_import_global.ClearSteps();
EXEC pkg_sepo_import_global.LoadSteps();

SELECT * FROM sepo_tech_steps_tree
WHERE
    is_step = 1
  AND
    blob_ IS NULL
  OR
    Trim(step_path) != Trim(blob_)
ORDER BY
  order_;

SELECT
  f.f_level,
  Count(DISTINCT r.f_key)
FROM
  sepo_eqp_model_folders f,
  sepo_eqp_model_records r
WHERE
    f.f_level = r.f_level * (-1)
GROUP BY
  f.f_level
HAVING
  Count(DISTINCT r.f_key) > 1;

SELECT * FROM sepo_eqp_model_records
WHERE
    f_level = -12581;