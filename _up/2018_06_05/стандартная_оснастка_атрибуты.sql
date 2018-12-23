DECLARE
  l_enumeration NUMBER;
  l_enum_name obj_enumerations.name%TYPE;
  l_attr_code NUMBER;
  l_attr_name obj_attributes.shortname%TYPE;
  l_group_code NUMBER;
  l_group_name obj_types_groups.name%TYPE;
  l_scheme_code NUMBER;
  l_scheme_name obj_types_schemes.name%TYPE;
BEGIN
  l_enum_name := '“ип оснастки';
  l_attr_name := '@“ип_оснастки';
  l_group_name := '—тандартна€';
  l_scheme_name := '¬ыбор схемы атрибутов дл€ стандартной оснастки';

  -- проверка на наличие перечислени€
  SELECT
    Max(code)
  INTO
    l_enumeration
  FROM
    obj_enumerations
  WHERE
      name = l_enum_name;

  -- если перечисление не найдено, то оно создаетс€
  IF l_enumeration IS NULL THEN
    l_enumeration := pkg_sepo_system_objects.createenumeration(l_enum_name);
  END IF;

  -- проверка на наличие атрибута с заданным перечислением
  SELECT
    Max(o.code)
  INTO
    l_attr_code
  FROM
    obj_attributes o,
    obj_enum_info i
  WHERE
      i.code = o.code
    AND
      o.objtype = 33
    AND
      o.attr_type = 10
    AND
      o.shortname = l_attr_name
    AND
      i.encode = l_enumeration;

  -- если атрибута нет, то он создаетс€
  IF l_attr_code IS NULL THEN
    l_attr_code := pkg_sepo_system_objects.createenumattr(
      pkg_sepo_system_objects.std_fixture,
      l_attr_name,
      l_attr_name,
      l_enumeration
    );

  END IF;

  -- наличие группы
  SELECT
    Max(code)
  INTO
    l_group_code
  FROM
    obj_types_groups
  WHERE
      objtype = 33
    AND
      name = l_group_name;

  IF l_group_code IS NULL THEN
    l_group_code := pkg_sepo_system_objects.creategroup(
      pkg_sepo_system_objects.std_fixture,
      l_group_name
    );

  END IF;

  -- схема по умолчанию
  l_scheme_code := pkg_sepo_system_objects.createdefaultscheme(
    pkg_sepo_system_objects.std_fixture,
    l_scheme_name
  );

  -- удаление содержимого схемы по умолчанию
  pkg_sepo_system_objects.deletegroupsfromscheme(l_scheme_code);

  -- добавление атрибута в схему по умолчанию
  pkg_sepo_system_objects.addattrtoscheme(
    l_scheme_code,
    l_group_code,
    l_attr_code
  );

  -- создание атрибутов
  -- если атрибут существует в системе, но его тип не совпадает,
  -- то атрибут пересоздаетс€
  FOR i IN (
    SELECT
      *
    FROM
      v_sepo_std_attrs a
  ) LOOP
    NULL;
  END LOOP;

  -- создание схем

  -- св€зь схем с перечислением, синхронизаци€

END;
/