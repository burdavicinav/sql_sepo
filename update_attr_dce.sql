DECLARE
  TYPE dict_attrs IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  attrs dict_attrs;
BEGIN
  -- получить код атрибута DCE
  FOR i IN (
    SELECT
      objType,
      code
    FROM
      obj_attributes
    WHERE
        objType IN (1,2,5,22)
      AND
        shortName LIKE 'DCE'
  ) LOOP
    attrs(i.objType) := i.code;
  END LOOP;

  -- поиск по chndn
  FOR i IN (
    SELECT
      dce.chndn,
      bo.code AS boCode,
      bo.TYPE AS objType,
      bo.name AS boName,
      dce.dce
    FROM
      sepo_dce_list dce,
      business_objects bo
    WHERE
        dce.chndn = bo.name
      AND
        bo.TYPE IN (1,2,5,22)
  ) LOOP
    -- обновление атрибута
    EXECUTE IMMEDIATE
      'UPDATE obj_attr_values_' || i.objType ||
      ' SET A_' || attrs(i.objType) || '=:1' ||
      ' WHERE soCode=:2'
    USING
      i.dce,
      i.boCode;

  END LOOP;

END;
/