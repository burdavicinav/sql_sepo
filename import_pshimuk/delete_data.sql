DECLARE
  value_ NUMBER := NULL;
BEGIN
  -- удаление норм
  DELETE FROM det_expense;

  -- удаление данных по материалам
  DELETE FROM main_materials;
  UPDATE details SET matCode = NULL;
  UPDATE spcMaterials SET matCode = NULL;
  UPDATE standarts SET matCode = NULL;

  pkg_sepo_attr_operations.Init(2);
  pkg_sepo_attr_operations.AddAttrData (
        p_name => 'Материал',
        p_type => 6,
        p_value => value_
      );

  FOR i IN (
    SELECT
      code
    FROM
      omp_objects
    WHERE
        objType = 2

  ) LOOP
    pkg_sepo_attr_operations.UpdateAttrs( i.code );

  END LOOP;

  pkg_sepo_attr_operations.Clear();

END;
/