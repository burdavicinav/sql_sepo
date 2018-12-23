--DROP TRIGGER taiud_sepo_material_to_group

CREATE OR REPLACE TRIGGER taiud_sepo_material_to_group
AFTER INSERT ON material_to_group
FOR EACH ROW
DECLARE
  l_groupIsFoxPro NUMBER;
  l_mat_soCode NUMBER;
  l_groupCode groups_in_classify.grCode%TYPE;

  l_gruCode NUMBER;
BEGIN
  SELECT
    Count(*)
  INTO
    l_groupIsFoxPro
  FROM
    groups_in_classify gr,
    classify cl
  WHERE
      gr.code = :new.groupCode
    AND
      cl.code = gr.clCode
    AND
      cl.clCode = 'FoxPro';

  IF l_groupIsFoxPro > 0 THEN
    SELECT
      m.soCode
    INTO
      l_mat_soCode
    FROM
      materials m
    WHERE
        m.code = :new.materialCode;

    SELECT
      gr.grCode
    INTO
      l_groupCode
    FROM
      groups_in_classify gr
    WHERE
        gr.code = :new.groupCode;

    SELECT
      code
    INTO
      l_gruCode
    FROM
      obj_attributes
    WHERE
        objType = 1000001
      AND
        shortName = 'GRU';

    EXECUTE IMMEDIATE
      'UPDATE obj_attr_values_1000001 SET A_' || l_gruCode ||
      ' = :1 WHERE soCode = :2'
    USING
      l_groupCode,
      l_mat_soCode;

  END IF;

END;
/