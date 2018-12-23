DECLARE
  l_old_cut NUMBER;
  l_new_cut NUMBER;
  l_query VARCHAR2(500);
  l_cut_uncorrect_value VARCHAR2(255);

  ATTR_NOT_EXISTS_EXCEPTION EXCEPTION;
  ATTR_NOT_CORRECT_VALUE_EXCEPTION EXCEPTION;
BEGIN
  -- скрипт переносит значения из строкового атрибута "Сечение"
  -- в новый числовой атрибут "Сечение_".
  -- ориентирован на кодировку RUSSIAN_RUSSIA.CL8MSWIN1251

  -- получение кодов атрибутов "Сечение" и "Сечение_"
  SELECT
    Max(code)
  INTO
    l_old_cut
  FROM
    obj_attributes
  WHERE
      objType = 1000001
    AND
      shortName = 'Сечение';

  SELECT
    Max(code)
  INTO
    l_new_cut
  FROM
    obj_attributes
  WHERE
      objType = 1000001
    AND
      shortName = 'Сечение_';

  -- если хотя бы одного из них не существует, то ошибка
  IF l_old_cut + l_new_cut IS NULL THEN
    RAISE ATTR_NOT_EXISTS_EXCEPTION;
  END IF;

  -- далее проверка на корректность значений атрибута "Сечение"
  l_query :=
    'SELECT max(A_' || l_old_cut || ') FROM obj_attr_values_1000001 ' ||
    'WHERE NOT regexp_like(A_' || l_old_cut || ', ''^\d+([\.,]\d+)?$'')';

--  Dbms_Output.put_line(l_query);

  EXECUTE IMMEDIATE l_query INTO l_cut_uncorrect_value;

  -- если есть хотя бы одно значение, которое невозможно перевести в число,
  -- то ошибка
  IF l_cut_uncorrect_value IS NOT NULL THEN
    RAISE ATTR_NOT_CORRECT_VALUE_EXCEPTION;
  END IF;

  -- если все значения корректны, то осуществляется перевод из строки в число
  -- и заполнение атрибута "Сечение_"
  l_query :=
    'UPDATE obj_attr_values_1000001 attr SET A_' || l_new_cut ||
    ' = (' ||
        'SELECT to_number(Replace(attr_.A_' || l_old_cut || ', ''.'', '','')) ' ||
        'FROM obj_attr_values_1000001 attr_ ' ||
        'WHERE attr_.soCode = attr.soCode ' ||
        ')' ||
    'WHERE attr.A_' || l_old_cut || ' IS NOT NULL';

--  Dbms_Output.put_line(l_query);

  EXECUTE IMMEDIATE l_query;

  COMMIT;

EXCEPTION
  WHEN ATTR_NOT_EXISTS_EXCEPTION THEN
    Raise_Application_Error(
      -20101, 'Не найден атрибут!');
  WHEN ATTR_NOT_CORRECT_VALUE_EXCEPTION THEN
    Raise_Application_Error(
      -20102, 'Некорректное значение атрибута: ' || l_cut_uncorrect_value);
END;
/