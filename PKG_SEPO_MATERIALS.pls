PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_materials
CREATE OR REPLACE PACKAGE pkg_sepo_materials
AS
  -- ручное обновление поля GRU отключено
  IsUpdateGRU BOOLEAN := FALSE;
  IsInsertMaterial BOOLEAN := FALSE;

  FUNCTION CheckUniqueCode(p_plCode VARCHAR2) RETURN BOOLEAN;
  PROCEDURE DeleteStockItem(p_soCode NUMBER);

  PROCEDURE UpdateAttrCodeMaterial;
  PROCEDURE UpdateAttrCodeMaterial(p_code NUMBER);
END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_materials
CREATE OR REPLACE PACKAGE BODY pkg_sepo_materials
AS
  FUNCTION CheckUniqueCode(p_plCode VARCHAR2) RETURN BOOLEAN
  IS
    l_exists NUMBER;
  BEGIN
    SELECT
      Count(*)
    INTO
      l_exists
    FROM
      (
      SELECT
        plCode
      FROM
        materials
      UNION ALL
      SELECT
        Sign
      FROM
        stock_other
      WHERE
          is_annul = 0
      )
    WHERE
        plCode = p_plCode;

    RETURN NOT (l_exists > 1);

  END;

  PROCEDURE DeleteStockItem(p_soCode NUMBER)
  IS
    l_stockobj_code NUMBER;
  BEGIN
    SELECT
      code
    INTO
      l_stockobj_code
    FROM
      stockobj
    WHERE
        soCode = p_soCode;

    DELETE FROM stockObj_to_group
    WHERE
        stockobjCode = l_stockobj_code;

    DELETE FROM stockobj
    WHERE
        code = l_stockobj_code;

    DELETE FROM stock_other
    WHERE
        code = p_soCode;

    DELETE FROM omp_objects
    WHERE
        code = p_soCode;
  END;

  PROCEDURE UpdateAttrCodeMaterial
  IS
    l_attr_code NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_attr_code
    FROM
      obj_attributes
    WHERE
        objtype = 1000045
      AND
        shortname = 'КодМат';

    IF l_attr_code IS NULL THEN
      Raise_Application_Error(-20101, 'Атрибут не найден!');
    END IF;

    EXECUTE IMMEDIATE
      'update obj_attr_values_1000045 a set a_' || l_attr_code ||
      '=(select s.sign from stock_other s where s.code = a.socode)';

  END;

  PROCEDURE UpdateAttrCodeMaterial(p_code NUMBER)
  IS
    l_attr_code NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_attr_code
    FROM
      obj_attributes
    WHERE
        objtype = 1000045
      AND
        shortname = 'КодМат';

    IF l_attr_code IS NULL THEN
      Raise_Application_Error(-20101, 'Атрибут не найден!');
    END IF;

    EXECUTE IMMEDIATE
      'update obj_attr_values_1000045 a set a_' || l_attr_code ||
      '=(select s.sign from stock_other s where s.code = a.socode) ' ||
      'where a.socode = :1'
    USING
      p_code;

  END;

END;
/

