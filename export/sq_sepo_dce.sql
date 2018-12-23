--DROP SEQUENCE sq_sepo_dce;

DECLARE
  l_query VARCHAR2(1000);

--  TYPE DictAttrs IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--  l_attrs DictAttrs;

--  l_max_value NUMBER;
  l_startIndexPosition NUMBER := 100000300000;
BEGIN
--  l_attrs.DELETE();

--  FOR i IN (
--    SELECT
--      code,
--      objType
--    FROM
--      obj_attributes
--    WHERE
--        name = 'DCE'
--      AND
--        objType IN (1,2,3,5)

--    ) LOOP
--      l_attrs(i.objType) := i.code;

--    END LOOP;

--  l_query :=
--   'SELECT ' ||
--      'Max(To_Number(code)) ' ||
--    'FROM ' ||
--      '(' ||
--      'SELECT A_' || l_attrs(1) || ' AS code, 1 AS tp FROM obj_attr_values_1 ' ||
--      'UNION ' ||
--      'SELECT A_' || l_attrs(2) || ', 2 FROM obj_attr_values_2 ' ||
--      'UNION ' ||
--      'SELECT A_' || l_attrs(3) || ', 3 FROM obj_attr_values_3 ' ||
--      'UNION ' ||
--      'SELECT A_' || l_attrs(5) || ', 5 FROM obj_attr_values_5 ' ||
--      ')';

--  EXECUTE IMMEDIATE l_query INTO l_max_value;

--  Dbms_Output.put_line(l_max_value);

  IF pkg_sepo_export_settings.isResetDCESequence THEN
    l_query := 'CREATE SEQUENCE sq_sepo_dce START WITH ' || l_startIndexPosition;
    EXECUTE IMMEDIATE l_query;

  END IF;

END;
/