PROMPT CREATE OR REPLACE VIEW v_sepo_tech_processes
CREATE OR REPLACE VIEW v_sepo_tech_processes (
  id,
  kind,
  key_,
  designation,
  name,
  doc_id,
  dce_cnt,
  dce_cnt_tp,
  tptype,
  remark
) AS
SELECT
  t.id,
  t.kind,
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  t.dce_cnt,
  t.dce_cnt_tp,
  CASE
    WHEN t.kind = 1 AND t.dce_cnt <= 1 THEN 0
    WHEN t.kind IN (6,7) OR dce_cnt > 1 THEN 3
  END tptype,
  regexp_replace(c.comment_, '^0\s+', '') AS remark
FROM
  v_sepo_tech_processes_base t
  left JOIN
  sepo_tp_comments c
  ON
      c.id_tp = t.id
/

