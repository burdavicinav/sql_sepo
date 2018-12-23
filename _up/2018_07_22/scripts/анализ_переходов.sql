-- незагруженные переходы
SELECT
  *
FROM
  v_sepo_import_tech_steps s,
  sepo_tech_step_texts t
WHERE
    t.f_level (+)= s.f_level
  AND
    NOT EXISTS (
      SELECT
        1
      FROM
        v_sepo_technological_steps s_
      WHERE
          s_.steptext = s.steptext
    );

--SELECT
--  *
--FROM
--  v_sepo_technological_steps s
--WHERE
--    NOT EXISTS (
--      SELECT
--        1
--      FROM
--        v_sepo_import_tech_steps s_
--      WHERE
--          s_.steptext = s.steptext
--    );

-- привязка переходов к ТП
SELECT
  t.id,
  operkey,
  order_,
  stepcode
FROM
  sepo_tp_steps t
  left JOIN
  (
  SELECT
    sp.f_level,
    omp.stepcode
  FROM
    v_sepo_import_tech_steps sp,
    v_sepo_technological_steps omp
  WHERE
      sp.steptext = omp.steptext
  ) s
  ON
      t.reckey = s.f_level;

