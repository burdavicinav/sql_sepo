CREATE OR REPLACE TRIGGER tbu_sepo_materials
BEFORE UPDATE ON materials
FOR EACH ROW
DECLARE
  l_cnt NUMBER;

  l_gruCode NUMBER;
  l_isGRUExists BOOLEAN;
  l_gruValue groups_in_classify.grCode%TYPE;
BEGIN
  SELECT
    code
  INTO
    l_gruCode
  FROM
    obj_attributes
  WHERE
      objtype = 1000001
    AND
      shortName LIKE 'GRU';

  l_isGRUExists := FALSE;
  l_gruValue := NULL;

  IF pkg_sepo_materials.IsInsertMaterial THEN
    SELECT
      Count(*)
    INTO
      l_cnt
    FROM
      material_to_group l,
      groups_in_classify gr,
      classify cl
    WHERE
        l.materialCode = :new.code
      AND
        gr.code = l.groupCode
      AND
        cl.code = gr.clCode
      AND
        cl.clCode = 'FoxPro';

    -- если классификатор задан
    IF l_cnt > 0 THEN
      FOR i IN (
        SELECT
          gr.grCode
        FROM
          material_to_group l,
          groups_in_classify gr,
          classify cl
        WHERE
            l.materialCode = :new.code
          AND
            gr.code = l.groupCode
          AND
            cl.code = gr.clCode
          AND
            cl.clCode = 'FoxPro'

      ) LOOP
        l_isGRUExists := TRUE;
        l_gruValue := i.grCode;

      END LOOP;

      EXECUTE IMMEDIATE
        'UPDATE obj_attr_values_1000001 SET A_' || l_gruCode ||
        ' = :1 WHERE soCode = :2'
      USING
        l_gruValue,
        :new.soCode;

    ELSE
      EXECUTE IMMEDIATE
        'SELECT A_' || l_gruCode ||
        ' FROM obj_attr_values_1000001 ' ||
        ' WHERE soCode = :1'
      INTO
        l_gruValue
      USING
        :new.soCode;

      SELECT
        Count(*)
      INTO
        l_cnt
      FROM
        groups_in_classify gr,
        classify cl
      WHERE
          gr.clCode = cl.code
        AND
          gr.grCode = l_gruValue
        AND
          cl.clType = 12
        AND
          cl.clCode = 'FoxPro';

      IF l_cnt > 0 THEN
        INSERT INTO material_to_group
        SELECT
          :new.code,
          gr.code
        FROM
          groups_in_classify gr,
          classify cl
        WHERE
            gr.clCode = cl.code
          AND
            gr.grCode = l_gruValue
          AND
            cl.clType = 12
          AND
            cl.clCode = 'FoxPro';

      END IF;

    END IF;

    pkg_sepo_materials.IsInsertMaterial := FALSE;

  ELSE
    FOR i IN (
      SELECT
        gr.grCode
      FROM
        material_to_group l,
        groups_in_classify gr,
        classify cl
      WHERE
          l.materialCode = :new.code
        AND
          gr.code = l.groupCode
        AND
          cl.code = gr.clCode
        AND
          cl.clCode = 'FoxPro'

    ) LOOP
      l_isGRUExists := TRUE;
      l_gruValue := i.grCode;

    END LOOP;

    EXECUTE IMMEDIATE
      'UPDATE obj_attr_values_1000001 SET A_' || l_gruCode ||
      ' = :1 WHERE soCode = :2'
    USING
      l_gruValue,
      :new.soCode;

  END IF;



END;
/

--DROP TRIGGER tbiu_sepo_attrs_on_materials