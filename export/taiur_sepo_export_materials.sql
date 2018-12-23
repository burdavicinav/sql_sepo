CREATE OR REPLACE TRIGGER taiur_sepo_export_materials
AFTER UPDATE OR INSERT ON materials
FOR EACH ROW

DECLARE
  l_create_user NUMBER;
  l_modify_user NUMBER;

  l_cnt NUMBER;
  l_gru_code NUMBER;
  l_gru NUMBER;
BEGIN
  -- строчный триггер сохраняет данные об изменяемом материале

  IF INSERTING THEN
    pkg_sepo_materials.IsInsertMaterial := TRUE;
--    SELECT
--      code
--    INTO
--      l_gru_code
--    FROM
--      obj_attributes
--    WHERE
--        objType = 1000001
--      AND
--        shortName = 'GRU';

--    EXECUTE IMMEDIATE
--      'SELECT A_' || l_gru_code ||
--      ' FROM obj_attr_values_1000001 ' ||
--      ' WHERE soCode = :1'
--    INTO
--      l_gru
--    USING
--      :new.soCode;

--    SELECT
--      Count(*)
--    INTO
--      l_cnt
--    FROM
--      groups_in_classify gr,
--      classify cl
--    WHERE
--        gr.clCode = cl.code
--      AND
--        gr.grCode = l_gru
--      AND
--        cl.clType = 12
--      AND
--        cl.clCode = 'FoxPro';

--    IF l_cnt > 0 THEN
--      INSERT INTO material_to_group
--      SELECT
--        :new.code,
--        gr.code
--      FROM
--        groups_in_classify gr,
--        classify cl
--      WHERE
--          gr.clCode = cl.code
--        AND
--          gr.grCode = l_gru
--        AND
--          cl.clType = 12
--        AND
--          cl.clCode = 'FoxPro';

--    END IF;

  END IF;

  -- определение пользователя, редактирующего запись
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- определение пользователя, создавшего запись
  IF :new.state = 0 THEN
    l_create_user := l_modify_user;

  ELSE
    SELECT
      userCode
    INTO
      l_create_user
    FROM
      xml_history
    WHERE
        xmlDocType = 1000001
      AND
        sql_type = 2
      AND
        ompCode = :new.code;

  END IF;

  -- сохранение данных
  INSERT INTO sepo_materials_temp
  VALUES
  (:new.soCode, :new.plCode, :new.measCode, :new.measCode2, :new.measCode3,
      :new.recDate, :new.updateDate, l_create_user, l_modify_user,
        :old.state, :new.state);

END;
/