SELECT * FROM obj_attributes
WHERE
    objtype = 60;

SELECT * FROM obj_attr_values_60;

SELECT * FROM obj_enumerations_values
WHERE
--    code = 101;
--  AND
    encode = 120;

SELECT * FROM letters;
SELECT * FROM businessobj_states
WHERE
    botype = 60;

SELECT * FROM businessobj_promotion_levels;

SELECT * FROM omp_objects;
SELECT * FROM konstrobj;
SELECT * FROM techprocesses;
SELECT * FROM techproc_comment;

SELECT * FROM operations_for_techprocesses;
SELECT * FROM steps_for_operation;
SELECT * FROM business_objects
WHERE
    doccode = 8640;

SELECT * FROM techparam_to_operation;
SELECT * FROM tpoper_mat_params;
SELECT * FROM workshops;
SELECT * FROM technology_operations;
SELECT * FROM techoper_instructions;
SELECT * FROM instructions;
SELECT * FROM technological_steps;
SELECT * FROM tpoper_performers;
SELECT * FROM tpstep_performers;
SELECT * FROM obj_attr_values_1000034;
SELECT * FROM professions;
SELECT * FROM eqp_model_to_techprocoper;
SELECT * FROM equipment_model;
SELECT * FROM fixture_to_operation;
SELECT * FROM fixture_to_step;
SELECT * FROM fixture_base;

SELECT * FROM steps_for_operation;
SELECT * FROM steps_for_oper_steptext;

SELECT * FROM classify
WHERE
    cltype = 6;

SELECT * FROM groups_in_classify
WHERE
    clcode = 2;

SELECT * FROM technological_steps;

SELECT * FROM v_sepo_tp_errors
WHERE
    id_cause = 2;

SELECT
  i.code AS stdcode,
  s.f_level
        FROM
          v_sepo_instructions_tb s,
          instructions i
        WHERE
            s.instruction = i.Sign

SELECT * FROM technological_steps
WHERE
    name = 'test';

SELECT * FROM steps_for_operation;
SELECT * FROM steps_for_oper_steptext;

SELECT
  a.socode,
  a.art_id,
  a.objtype,
  a.table_,
  a.tblkey,
  a.reckey,
  a.o_vo,
  k.unvcode,
  k.Sign,
  k.name
FROM
  v_sepo_fixture_attrs a,
  konstrobj k
WHERE
    k.bocode = a.socode
ORDER BY
  a.o_vo;

SELECT * FROM v_sepo_tp_tools WHERE catalog != 3709;

SELECT * FROM sepo_std_formulas WHERE id_tool = 693643;

SELECT * FROM sepo_std_table_fields WHERE id = 208714;

SELECT * FROM sepo_std_table_records;

SELECT * FROM sepo_std_tp_params;

SELECT
  a.socode,
  a.objtype,
  a.tblkey,
  a.reckey,
  a.o_vo,
  k.unvcode,
  k.Sign AS ksign,
  k.name AS kname,
  n.id_tool,
  n.name
FROM
  v_sepo_fixture_attrs a
  JOIN
  konstrobj k
  ON
      k.bocode = a.socode
  left JOIN
  v_sepo_std_formula_names n
  ON
      n.reckey = a.reckey
    AND
      n.tblkey = a.tblkey
    AND
      n.name = k.name
ORDER BY
  a.socode,
  n.id_tool;

SELECT * FROM v_sepo_std_formula_names WHERE reckey = 545236 AND tblkey = 3
SELECT * FROM v_sepo_fixture_attrs WHERE reckey = 545236 AND tblkey = 3
SELECT * FROM v_sepo_std_import WHERE reckey = 545236 AND tblkey = 3;

-- 134539
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.catalog,
  t.reckey AS tp_reckey,
  t.tblkey AS tp_tblkey,
  t.o_vo AS tp_vo,
  o.*
FROM
  v_sepo_tp_tools t
  left JOIN
  (
    SELECT
      a.socode,
      a.objtype,
      a.tblkey,
      a.reckey,
      a.o_vo,
      k.unvcode,
      k.Sign AS ksign,
      k.name AS kname,
      n.id_tool,
      n.name
    FROM
      v_sepo_fixture_attrs a
      JOIN
      konstrobj k
      ON
          k.bocode = a.socode
      left JOIN
      v_sepo_std_formula_names n
      ON
          n.reckey = a.reckey
        AND
          n.tblkey = a.tblkey
        AND
          n.name = k.name
        AND
          n.f_longname = 'Ïîëíîå íàèìåíîâàíèå'
  ) o
  ON
      t.reckey = o.reckey
    AND
      t.tblkey = o.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog NOT IN (3709, 4046, 4143, 4208)
--  AND
--    o.socode IS NULL
ORDER BY
  id;


SELECT
  objtype,
  Count(DISTINCT t.id)
FROM
  v_sepo_tp_tools t
  left JOIN
  v_sepo_fixture_attrs a
  ON
      a.o_vo = t.o_vo
    AND
      a.objtype IN (31,32)
WHERE
    t.catalog = 3709
GROUP BY
  a.objtype;

SELECT
--  DISTINCT name
  t.*,
  a.socode,
  b.TYPE,
  b.name
FROM
  v_sepo_tp_tools t
  left JOIN
  v_sepo_fixture_attrs a
  ON
      a.o_vo = t.o_vo
    AND
      a.objtype IN (31,32)
  left JOIN
  business_objects b
  ON
    b.code = a.socode
WHERE
    t.id IN (
      SELECT
        t.id--,
      --  Count(DISTINCT a.socode)
      FROM
        v_sepo_tp_tools t
        left JOIN
        v_sepo_fixture_attrs a
        ON
            a.o_vo = t.o_vo
          AND
            a.objtype IN (31,32)
      WHERE
          t.catalog = 3709
      GROUP BY
        t.id
      HAVING
        Count(DISTINCT a.socode) = 1
    )
  AND
    b.name LIKE '%ÑÁ'
--  AND
--    EXISTS (
--      SELECT
--        1
--      FROM
--        business_objects b_
--      WHERE
--          b_.code = b.code
--        AND
--          b_.TYPE IN (31,32)
--        AND
--          b_.name LIKE '%ÑÁ'
--        AND
--          EXISTS (
--            SELECT
--              1
--            FROM
--              specifications s
--            WHERE
--                s.spccode = b_.doccode
--          )

--    )
ORDER BY
  t.id,
  a.socode;

SELECT
  b.TYPE,
  b.name
FROM
  business_objects b
WHERE
    TYPE IN (31,32)
  AND
    name LIKE '%ÑÁ'
  AND
    EXISTS (
      SELECT
        1
      FROM
        specifications s
      WHERE
          s.spccode = b.doccode
    )
ORDER BY
  b.name;

SELECT
  s.Sign,
  k.itemtype,
  k.Sign
FROM
  konstrobj s,
  konstrobj k,
  specifications sp
WHERE
    sp.spccode = s.unvcode
  AND
    sp.code = k.unvcode
  AND
    s.itemtype IN (31, 32)
  AND
    s.Sign LIKE '%ÑÁ'
ORDER BY
  s.Sign,
  k.Sign;


SELECT
  a.objtype,
  a.table_,
  a.tblkey,
  a.reckey,
  a.o_vo,
  b.name
FROM
  business_objects b,
  v_sepo_fixture_attrs a
WHERE
    a.socode = b.code
  AND
    a.o_vo IN (
      SELECT
        o_vo
      FROM
        v_sepo_fixture_attrs
      WHERE
          objtype IN (31,32)
      GROUP BY
        o_vo
      HAVING
        Count(DISTINCT socode) > 1
    )
ORDER BY
  a.o_vo,
  b.name;