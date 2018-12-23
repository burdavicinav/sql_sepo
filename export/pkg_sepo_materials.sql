CREATE OR REPLACE PACKAGE pkg_sepo_materials
AS
  -- ручное обновление поля GRU отключено
  IsUpdateGRU BOOLEAN := FALSE;
  IsInsertMaterial BOOLEAN := FALSE;

  FUNCTION CheckUniqueCode(p_plCode VARCHAR2) RETURN BOOLEAN;
  PROCEDURE DeleteStockItem(p_soCode NUMBER );
END;
/

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
        sign
      FROM
        stock_other
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

END;
/