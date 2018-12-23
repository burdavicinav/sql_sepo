SELECT * FROM sepo_tp_entities_legend;
SELECT * FROM sepo_tp_entities;
SELECT * FROM sepo_tech_processes;
SELECT * FROM sepo_tp_to_dce;
SELECT * FROM sepo_tp_fields;
SELECT * FROM sepo_tp_comments;
SELECT * FROM sepo_tp_opers;
SELECT * FROM sepo_tp_oper_fields;
SELECT * FROM sepo_tp_oper_comments;
SELECT * FROM sepo_tp_steps;
SELECT * FROM sepo_tp_step_fields;
SELECT * FROM sepo_tp_step_comments;
SELECT * FROM sepo_tp_workers;
SELECT * FROM sepo_tp_worker_fields;
SELECT * FROM sepo_tp_equipments;
SELECT * FROM sepo_tp_equipment_fields;
SELECT * FROM sepo_tp_tools;
SELECT * FROM sepo_tp_tool_fields;

SELECT * FROM v_sepo_tp_tools;

SELECT * FROM sepo_tp_oper_fields;

SELECT * FROM sepo_import_log
WHERE
    msg LIKE '«‡„ÛÁÍ‡ Ù‡ÈÎ‡ “œ:%';

SELECT * FROM sepo_tp_entities
WHERE
    f_code = '%wrk';

SELECT * FROM v_sepo_tp_fields
WHERE
    Length(f_value) > 100;

SELECT DISTINCT f_code FROM v_sepo_tp_fields
WHERE
    Lower(f_code) LIKE 'ÙËÓ%'
ORDER BY
  f_value;

SELECT * FROM sepo_tp_entities
WHERE
    Lower(f_code) LIKE 'ÍÓÏ%'
--    id IN (32854, 32058)

SELECT * FROM sepo_tp_oper_fields
WHERE
    Length(f_value) > 500;

SELECT DISTINCT id_field FROM sepo_tp_oper_comments;

SELECT * FROM sepo_std_tables
WHERE
    f_table = 'TBL000642';

SELECT * FROM sepo_std_records
WHERE
    id_table = 20692;

SELECT * FROM sepo_std_table_records
WHERE
    id_table = 20692;

SELECT * FROM sepo_tp_tools
WHERE
    tblkey = 19479;

SELECT * FROM sepo_tp_tool_fields
WHERE
--    field_name = 'OsRc'
--  AND
    id_tool = 160934;


SELECT * FROM sepo_std_records
WHERE
    f_key = 548798;
--    field_name = 'Œ—Õ'
--  AND
--    f_value LIKE ' ¿À»¡–%œ–Œ¡ ¿%8133-0901%';

SELECT * FROM sepo_tp_tools
WHERE
    id = 160934;

SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.date_,
  t.kind,
  t.count_,
  t.reckey,
  f.f_value,
  t.tblkey
FROM
  sepo_tp_tools t
  left JOIN
  sepo_tp_tool_fields f
  ON
    f.id_tool = t.id
  AND
    f.field_name = 'OsRc'
WHERE
    f.f_value = 560866
  AND
    t.tblkey = 4

SELECT * FROM sepo_tp_tool_fields
WHERE
    id_tool IN (258313)