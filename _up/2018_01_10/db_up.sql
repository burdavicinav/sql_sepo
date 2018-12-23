DELETE FROM sepo_task_folder_list
WHERE
    Lower(name) LIKE '%ÚÂÒÚ%';

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
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', '≈“Œ–¿Õ ’—¬Ã') AS f_name,
    Count(DISTINCT id) AS cnt_recs
  FROM
    sepo_eqp_model_folders
  GROUP BY
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', '≈“Œ–¿Õ ’—¬Ã')
  ) fd
WHERE
    m.f_key = fd.f_key;