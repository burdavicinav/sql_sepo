-- ВНИМАНИЕ! Скрипт по обновлению децимального номера.
-- В начале происходит отключение штатных триггеров,
-- в связи с этим выполнять скрипт только при отсутствии пользователей в БД.

-- Не забудь после выполнения включить триггеры.

ALTER TRIGGER taiud_konstrobj_sosign DISABLE;
ALTER TRIGGER taiur_konstrobj_sosign DISABLE;
ALTER TRIGGER taur_konstrobj_sosign DISABLE;
ALTER TRIGGER tbiu_konstrobj_sosign DISABLE;
ALTER TRIGGER tua_konstrobj DISABLE;
ALTER TRIGGER tub_stockobj DISABLE;
ALTER TRIGGER tbiu_stockobj DISABLE;
ALTER TRIGGER taiur_stockobj DISABLE;
ALTER TRIGGER taiud_stockobj DISABLE;
ALTER TRIGGER tbu_sepo_konstrobj DISABLE;
ALTER TRIGGER tbu_sepo_business_objects DISABLE;

DECLARE
  l_prodcode NUMBER;
  l_sign VARCHAR2(121);
BEGIN
  FOR i IN (
--    SELECT
--      a.*
--    FROM
--      view_sepo_spc_materials_update a,
--      (
--      SELECT
--        new_mat_sign
--      FROM
--        view_sepo_spc_materials_update
--      GROUP BY
--        new_mat_sign
--      HAVING
--        Count(DISTINCT mat_prodcode) = 1
--      ) b
--    WHERE
--        a.new_mat_sign = b.new_mat_sign
----      AND
----        a.mat_sign != a.new_mat_sign
--    ORDER BY
--      a.new_mat_sign,
--      a.mat_sign
    SELECT
      a.*
    FROM
      view_sepo_spc_materials_update a,
      (
      SELECT
        up.new_mat_sign
      FROM
        view_sepo_spc_materials_update up
      WHERE
        regexp_replace(up.spec_sign, '\W', '') =
          regexp_replace(up.spec_section, '\W', '')
      GROUP BY
        up.new_mat_sign
      HAVING
        Count(DISTINCT up.mat_prodcode) = 1
      ) b
    WHERE
        a.new_mat_sign = b.new_mat_sign
    --  AND
    --    a.mat_sign = a.new_mat_sign
      AND
        regexp_replace(a.spec_sign, '\W', '') =
          regexp_replace(a.spec_section, '\W', '')
    ORDER BY
      a.new_mat_sign,
      a.mat_sign
  ) LOOP
    l_prodcode := i.mat_prodcode;
    l_sign := i.new_mat_sign;
--    Dbms_Output.put_line(i.mat_prodcode || ' ' || i.new_mat_sign);
    -- bo_production
    UPDATE bo_production SET Sign = i.new_mat_sign
    WHERE
        code = i.mat_prodcode;

    -- business_objects
    UPDATE business_objects SET name = i.new_mat_sign
    WHERE
        prodCode = i.mat_prodcode;

    -- konstrobj
    UPDATE konstrobj SET Sign = i.new_mat_sign
    WHERE
        prodCode = i.mat_prodcode;

    -- spcMaterials
    UPDATE spcMaterials SET Sign = i.new_mat_sign
    WHERE
        code IN (
          SELECT
            unvCode
          FROM
            konstrobj
          WHERE
              prodCode = i.mat_prodcode
        );

    -- stockobj
    UPDATE stockObj
    SET
      desc_update_check = 1,
      description = i.new_mat_sign,
      Sign = i.new_mat_sign
    WHERE
        fk_bo_production = i.mat_prodcode;

  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    Dbms_Output.put_line(l_prodcode || ' ' || l_sign);
    RAISE;

END;
/

ALTER TRIGGER taiud_konstrobj_sosign ENABLE;
ALTER TRIGGER taiur_konstrobj_sosign ENABLE;
ALTER TRIGGER taur_konstrobj_sosign ENABLE;
ALTER TRIGGER tbiu_konstrobj_sosign ENABLE;
ALTER TRIGGER tua_konstrobj ENABLE;
ALTER TRIGGER tub_stockobj ENABLE;
ALTER TRIGGER tbiu_stockobj ENABLE;
ALTER TRIGGER taiur_stockobj ENABLE;
ALTER TRIGGER taiud_stockobj ENABLE;
ALTER TRIGGER tbu_sepo_konstrobj ENABLE;
ALTER TRIGGER tbu_sepo_business_objects ENABLE