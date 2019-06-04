CREATE GLOBAL TEMPORARY TABLE sepo_obj_attr_values_temp (
  socode NUMBER,
  num_value NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE PROCEDURE p_sepo_attr_num_to_string (p_attrcode NUMBER)
IS
  l_objtype NUMBER;
  l_attrtype NUMBER;
  l_sql VARCHAR2(1000);
BEGIN
  -- информация об атрибуте
  SELECT
    objtype,
    attr_type
  INTO
    l_objtype,
    l_attrtype
  FROM
    obj_attributes
  WHERE
      code = p_attrcode;

  IF l_attrtype NOT IN (2,3) THEN
    Raise_Application_Error(-20101, 'Тип атрибута должен быть "Число" или "Целое число"!');

  END IF;

  -- очищение данных
  DELETE FROM sepo_obj_attr_values_temp;

  UPDATE obj_attributes
  SET
    attr_type = 1,
    value_type = 1,
    value_size = 255
  WHERE
      code = p_attrcode;

  IF l_attrtype = 2 THEN
    DELETE FROM obj_float_prop WHERE code = p_attrcode;

  ELSE
    DELETE FROM obj_integer_prop WHERE code = p_attrcode;

  END IF;

  INSERT INTO obj_char_prop (
    code, maxlen
  )
  VALUES (
    p_attrcode, 255
  );

  l_sql := 'insert into sepo_obj_attr_values_temp ';
  l_sql := l_sql || 'select socode, a_' || p_attrcode
    || ' from obj_attr_values_' || l_objtype;

  EXECUTE IMMEDIATE l_sql;

  l_sql := 'alter table obj_attr_values_' || l_objtype ||
    ' drop column a_' || p_attrcode;

  EXECUTE IMMEDIATE l_sql;

  l_sql := 'alter table obj_attr_values_' || l_objtype ||
    ' add a_' || p_attrcode || ' varchar2(255)';

  EXECUTE IMMEDIATE l_sql;

  l_sql := 'update obj_attr_values_' || l_objtype
    || ' t set t.a_' || p_attrcode
    || '= (select to_char(v.num_value) from sepo_obj_attr_values_temp v '
    || 'where v.socode = t.socode)';

  EXECUTE IMMEDIATE l_sql;

  DELETE FROM sepo_obj_attr_values_temp;

END;
/

CREATE OR REPLACE PROCEDURE p_sepo_scheme_attr_num_to_str(p_objtype NUMBER, p_schemename VARCHAR2)
IS
BEGIN
  FOR i IN (
    SELECT DISTINCT
      a.code AS attrcode,
      a.name AS attrname
    FROM
      obj_types_schemes s
      JOIN
      group_to_scheme g
      ON
          g.scheme = s.code
      JOIN
      attr_position ap
      ON
          ap.groupscheme = g.code
      JOIN
      obj_attributes a
      ON
          a.code = ap.attr
    WHERE
        s.objtype = p_objtype
      AND
        s.name = p_schemename
      AND
        a.attr_type IN (2,3)

  ) LOOP
    p_sepo_attr_num_to_string(i.attrcode);

    Dbms_Output.put_line('Конвертация атрибута "' || i.attrname || '" выполнена!');

  END LOOP;

END;
/