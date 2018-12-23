EXEC pkg_sepo_import_global.fix_generate_objects();


SELECT * FROM sepo_std_expressions;
SELECT * FROM sepo_std_expressions WHERE id_tool IS NOT NULL;

SELECT * FROM sepo_std_expressions_temp;

SELECT * FROM sepo_std_expr_field_values;

SELECT * FROM sepo_std_tp_params_temp;

SELECT * FROM sepo_std_tp_params;

52(AW) 32õ40õ6 ?Ïøê1? ?Ïøê2? ?Ïøê3? ?Ïøê4? ?Ïøê6?ì/ñ;

SELECT
  id_table,
  param,
FROM
  sepo_std_tp_params p
  JOIN
  sepo_std_expressions e
  ON
      e.id = p.id_expr
  JOIN
  sepo_std_table_records r
  ON
      r.id = e.id_record;

SELECT * FROM sepo_std_attrs;

SELECT * FROM v_sepo_std_import;

SELECT
  DISTINCT f_longname
FROM
  sepo_std_expressions e
  JOIN
  sepo_std_table_fields f
  ON
      f.id = e.id_expr;

SELECT
  id_record,
  Upper(field_name) AS field,
  REPLACE (imp_field_value, '~', ' ') AS value_
FROM
  v_sepo_std_field_values
WHERE
    Upper(field_name) IN (
      'ÎÁÎÇÍÀ×ÅÍÈÅ ÄËß ÂÎ',
      'ÍÀÈÌÅÍÎÂÀÍÈÅ ÄËß ÂÎ',
      'ÏÎËÍÎÅ ÍÀÈÌÅÍÎÂÀÍÈÅ'
    )
  AND
    field_type != 'IEM_EXPRESSION'

UNION ALL

SELECT
  e.id_record,
  Upper(f.f_longname) AS field,
  e.expr_value
FROM
  sepo_std_expressions e
  JOIN
  sepo_std_table_fields f
  ON
      f.id = e.id_expr
WHERE
    Upper(f.f_longname) IN (
      'ÎÁÎÇÍÀ×ÅÍÈÅ ÄËß ÂÎ',
      'ÍÀÈÌÅÍÎÂÀÍÈÅ ÄËß ÂÎ',
      'ÏÎËÍÎÅ ÍÀÈÌÅÍÎÂÀÍÈÅ'
    )
GROUP BY
  e.id_record,
  f.f_longname,
  e.expr_value;

SELECT
  id_record,
  Count(DISTINCT params)
FROM
  (
  SELECT
    e.id_record,
    e.id_expr,
    id_tool,
    listagg(p.param) within GROUP (ORDER BY p.param) AS params
  FROM
    sepo_std_expressions e
    JOIN
    sepo_std_tp_params p
    ON
        p.id_expr = e.id
  WHERE
      id_tool IS NOT NULL
  GROUP BY
    e.id_record,
    e.id_expr,
    id_tool
  ORDER BY
    id_record,
    id_expr
  )
GROUP BY
  id_record
HAVING
  Count(DISTINCT params) > 1;


SELECT
  *
FROM
  sepo_std_expressions e
WHERE
    EXISTS (
      SELECT 1 FROM sepo_std_expressions e_ WHERE e_.id_record = e.id_record AND e_.id_tool IS NULL
    )
  AND
    EXISTS (
      SELECT 1 FROM sepo_std_expressions e_ WHERE e_.id_record = e.id_record AND e_.id_tool IS NOT NULL
    )
ORDER BY
  id_record,
  id_expr;

SELECT
    id_record,
    Max(id_tool)
  FROM
    v_sepo_std_expressions_group
GROUP BY
  id_record,
  id_tool;

SELECT
  DISTINCT Upper(f_longname)
FROM
  sepo_std_expressions e
  JOIN
  sepo_std_table_fields f
  ON
      f.id = e.id_expr;

SELECT
  signvo,
  Count(DISTINCT namevo)
FROM
  sepo_std_objects
GROUP BY
  signvo
HAVING
  Count(DISTINCT namevo) > 1;

SELECT * FROM sepo_std_objects WHERE signvo = '7100-0009';

SELECT * FROM konstrobj WHERE itemtype = 33 AND Sign LIKE 'test%';
SELECT * FROM business_objects WHERE type = 33 AND name LIKE 'test%';
SELECT * FROM stockobj WHERE Sign LIKE 'test1%';
SELECT * FROM fixture_base WHERE originalname LIKE 'test%';
SELECT * FROM standarts WHERE Sign LIKE 'test1%'