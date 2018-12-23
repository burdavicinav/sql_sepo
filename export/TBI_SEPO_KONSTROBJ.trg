PROMPT CREATE OR REPLACE TRIGGER tbi_sepo_konstrobj
CREATE OR REPLACE TRIGGER tbi_sepo_konstrobj
BEFORE INSERT ON konstrobj
FOR EACH ROW
DECLARE
  l_boCode NUMBER;
  l_revision NUMBER;
  l_dce_code NUMBER;
  l_dce_value VARCHAR2(18);
  l_query VARCHAR2(1000);
BEGIN
  SELECT
    code,
    revision
  INTO
    l_boCode,
    l_revision
  FROM
    business_objects
  WHERE
      prodCode = :new.prodCode
    AND
      docCode = :new.unvCode;

  IF :new.itemType IN (1, 2, 3, 5) THEN
    SELECT
      code
    INTO
      l_dce_code
    FROM
      obj_attributes
    WHERE
        objType = :new.itemType
      AND
        name = 'DCE';

    l_query := 'SELECT A_' || l_dce_code || ' FROM ' ||
                  'obj_attr_values_' || :new.itemType || ' WHERE soCode = :1';

    EXECUTE IMMEDIATE l_query INTO l_dce_value USING l_boCode;

    IF l_dce_value IS NULL OR l_revision = 0 THEN
      l_query := 'UPDATE obj_attr_values_' || :new.itemType || ' SET A_' ||
                    l_dce_code || ' = :1 WHERE soCode = :2';

      EXECUTE IMMEDIATE l_query USING sq_sepo_dce.NEXTVAL, l_boCode;

    END IF;


    IF :new.itemType = 3 THEN
      l_query := 'SELECT A_' || l_dce_code || ' FROM ' ||
                    'obj_attr_values_' || :new.itemType || ' WHERE soCode = :1';

      EXECUTE IMMEDIATE l_query INTO l_dce_value USING l_boCode;

      :new.Sign := l_dce_value;

      UPDATE business_objects SET name = l_dce_value
      WHERE
          code = l_boCode;

      UPDATE bo_production SET Sign = l_dce_value
      WHERE
          code = :new.prodCode;

    END IF;


  END IF;

END;
/

