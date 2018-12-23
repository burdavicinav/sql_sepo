--SELECT
--      *
--      FROM
--        spcList;

--SELECT * FROM business_objects
--WHERE
--    create_user = -2;


--SELECT

--SELECT
--  bo.code,
--  spc.firstApply
--FROM
--  business_objects bo,
--  spcList spc
--WHERE
--    bo.docCode = spc.code
--  AND
--    bo.TYPE = 1
--  AND
--    bo.create_user = -2
--  AND
--    bo.revision = 0;

CREATE OR REPLACE PACKAGE pkg_sepo_konstrobj
AS
  PROCEDURE UpdateImportIZD( p_boType NUMBER );
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_konstrobj
AS
  PROCEDURE UpdateImportIZD( p_boType NUMBER )
  IS
    l_izdCode NUMBER;
  BEGIN
    IF p_boType NOT IN (1, 2, 22) THEN RETURN; END IF;

    SELECT
      code
    INTO
      l_izdCode
    FROM
      obj_attributes
    WHERE
        objType = p_boType
      AND
        shortName = 'IZD';

    EXECUTE IMMEDIATE
      'UPDATE obj_attr_values_' || p_boType || ' attrs SET A_' || l_izdCode ||
        ' = ' ||
        ' ( ' ||
        'SELECT ' ||
          'dce.firstApply '||
        'FROM ' ||
          'business_objects bo,' ||
          CASE
            WHEN p_boType IN (1, 22) THEN 'spcList '
            ELSE
              'details '
          END || ' dce ' ||
        'WHERE ' ||
            'bo.docCode = dce.code ' ||
          'AND ' ||
            'bo.TYPE = ' || p_boType ||
          'AND ' ||
            'bo.create_user = -2 ' ||
          'AND ' ||
            'bo.revision = 0 ' ||
          'AND ' ||
            'bo.code = attrs.soCode ' ||
          ')';

  EXCEPTION
    WHEN No_Data_Found THEN
      Raise_Application_Error(-20111, '������� IZD �� ������!');
    WHEN OTHERS THEN
      RAISE;
  END;
END;
/