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
  l_codePrevRevision NUMBER;
BEGIN
  INSERT INTO sepo_konstrobj_temp (
    unvcode, itemtype, Sign,
    name, revision, prodcode
  )
  VALUES (
    :new.unvcode, :new.itemtype, :new.Sign,
    :new.name, :new.revision, :new.prodcode
  );

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

  IF :new.itemType IN (1, 2, 3, 5, 22) THEN
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

    -- генерация кода ДСЕ
    l_dce_value := NULL;

    -- если ревизия равна нулю (создание нового элемента)...
    IF l_revision > 0 THEN
      -- проверка на существование предыдущей ревизии
      SELECT
        Count(*)
      INTO
        l_codePrevRevision
      FROM
        business_objects
      WHERE
          prodCode = :new.prodCode
        AND
          revision = :new.revision - 1;

      -- если предыдущая ревизия существует...
      IF l_codePrevRevision > 0 THEN
        SELECT
          code
        INTO
          l_codePrevRevision
        FROM
          business_objects
        WHERE
            prodCode = :new.prodCode
          AND
            revision = :new.revision - 1;

        l_query := 'SELECT A_' || l_dce_code || ' FROM ' ||
                  'obj_attr_values_' || :new.itemType || ' WHERE soCode = :1';

        EXECUTE IMMEDIATE l_query INTO l_dce_value USING l_codePrevRevision;

      END IF;

    END IF;

    -- если нулевая ревизия или не существует предыдущей...
    IF l_dce_value IS NULL THEN
      -- то генерация нового кода
      l_dce_value := sq_sepo_dce.NEXTVAL;

    END IF;

    l_query := 'UPDATE obj_attr_values_' || :new.itemType || ' SET A_' ||
                    l_dce_code || ' = :1 WHERE soCode = :2';

    EXECUTE IMMEDIATE l_query USING l_dce_value, l_boCode;


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

  ELSIF :new.itemType = 4 THEN
    IF Length(:new.sign) > 9 THEN
      Raise_Application_Error(-20120, 'Длина обозначения превышает 9 символов!');

    END IF;

  END IF;

END;
/

