SELECT * FROM sepo_std_attr_union ORDER BY id;
SELECT * FROM sepo_std_attr_union_contents;

-- 2 �������, ��������� ����������

-- � ����� ������ ������� �� ����� ������ �������� �� ������ ���������
-- ����� ���������, � ������ �������� ����� ��������
-- ������� ������ ��������� "����������" � "����������1" �� ����� ����������

-- ��������, ������ ������ �� ����������. ���� ���-�� ����������, ������
-- �������� ������������
SELECT
  gs.scheme,
  c.id_group,
  Count(DISTINCT c.id)
FROM
  sepo_std_attr_union_contents c,
  obj_attributes a,
  attr_position p,
  group_to_scheme gs
WHERE
    a.objtype = 33
  AND
    a.name = c.attr_name
  AND
    p.attr = a.code
  AND
    gs.code = p.groupscheme
GROUP BY
  gs.scheme,
  c.id_group
HAVING
  Count(DISTINCT c.id) > 1;

-- ������ �� ������� �������� ���������
DECLARE
  l_groupattr NUMBER;
  l_sql VARCHAR2(1000);
  l_sqlattr VARCHAR2(1000);
  l_attrscheme NUMBER;
BEGIN
  SELECT
    code
  INTO
    l_attrscheme
  FROM
    obj_attributes
  WHERE
      objtype = 33
    AND
      shortname = '@���_��������';

  l_sql :=
    'UPDATE obj_attr_values_33 SET a_NEW = a_OLD ' ||
    'WHERE ' ||
    'socode IN (' ||
    'SELECT ' ||
      'socode ' ||
      'FROM ' ||
        'obj_attr_values_33,' ||
        'obj_enumerations_values ' ||
      'WHERE ' ||
        'a_' || l_attrscheme || '=code ' ||
        'and shortname=:1' ||
      ')';

  FOR i IN (
    SELECT
      g.id,
      g.group_name,
      Min(a.attr_type) AS attr_type
    FROM
      sepo_std_attr_union g,
      sepo_std_attr_union_contents c,
      obj_attributes a
    WHERE
        c.id_group = g.id
      AND
        a.name = c.attr_name
    GROUP BY
      g.id,
      g.group_name
    ORDER BY
      g.id

  ) LOOP
    -- �������� ������ ������������� ��������
    l_groupattr := pkg_sepo_system_objects.createattr (
      33,
      i.attr_type,
      NULL,
      '@' || i.group_name,
      NULL
    );

    FOR j IN (
      SELECT
        gs.scheme,
        regexp_replace(s.name, '^@', '') AS schemename,
        gs.groupcode,
        c.id_group,
        a.code AS attrcode,
        a.name AS attrname
      FROM
        sepo_std_attr_union_contents c,
        obj_attributes a,
        attr_position p,
        group_to_scheme gs,
        obj_types_schemes s
      WHERE
          c.id_group = i.id
        AND
          a.objtype = 33
        AND
          a.name = c.attr_name
        AND
          p.attr = a.code
        AND
          gs.code = p.groupscheme
        AND
          s.code = gs.scheme
      ORDER BY
        c.id_group

    ) LOOP
      pkg_sepo_system_objects.addattrtoscheme(
        j.scheme,
        j.groupcode,
        l_groupattr
      );

      l_sqlattr := REPLACE(l_sql, 'NEW', l_groupattr);
      l_sqlattr := REPLACE(l_sqlattr, 'OLD', j.attrcode);

      EXECUTE IMMEDIATE l_sqlattr USING j.schemename;

      INSERT INTO sepo_import_log (msg)
      VALUES (
        '������� �������� � �������� "' || j.attrname || '" �� ������� "' ||
        i.group_name || '" ������ ����� "' || j.schemename || '"'
      );

    END LOOP;

  END LOOP;

--  �������� ������ ���������
  FOR i IN (
    SELECT
      code,
      objtype,
      shortname
    FROM
      sepo_std_attr_union_contents c,
      obj_attributes a
    WHERE
        a.name = c.attr_name
      AND
        a.objtype = 33
  ) LOOP
    DELETE FROM attr_position
    WHERE
        attr = i.code;

    pkg_sepo_system_objects.dropattr(i.objtype, i.shortname);

  END LOOP;

--  ������ ������� � ����� ���������
  UPDATE obj_attributes
  SET
    name = regexp_replace(name, '^@', '')
  WHERE
      name IN (
        SELECT '@' || group_name FROM sepo_std_attr_union
      );

  COMMIT;

END;
/

-- ������ �� ������� �������� � �������� "��������_2" �� "��������"
-- ������, ����� � ���� �������� ��������� ��� ��������
DECLARE
  l_encode NUMBER;
  l_enval NUMBER;
  l_groupattr NUMBER;
  l_sql VARCHAR2(1000);
  l_sqlattr VARCHAR2(1000);
  l_attrscheme NUMBER;
BEGIN
  SELECT
    code
  INTO
    l_attrscheme
  FROM
    obj_attributes
  WHERE
      objtype = 33
    AND
      shortname = '@���_��������';

  SELECT
    e.encode,
    v.code AS val
  INTO
    l_encode,
    l_enval
  FROM
    obj_attributes a,
    obj_enum_info e,
    obj_enumerations_values v
  WHERE
      a.objtype = 33
    AND
      e.code = a.code
    AND
      v.encode = e.encode
    AND
      a.name IN ('��������', '��������_2')
    AND
      v.shortname = '�';

  l_sql :=
    'UPDATE obj_attr_values_33 SET a_NEW=:1 ' ||
    'WHERE ' ||
    'socode IN (' ||
    'SELECT ' ||
      'socode ' ||
      'FROM ' ||
        'obj_attr_values_33,' ||
        'obj_enumerations_values ' ||
      'WHERE ' ||
        'a_' || l_attrscheme || '=code ' ||
        'and a_OLD is not null ' ||
        'and shortname=:2' ||
      ')';

  l_groupattr := pkg_sepo_system_objects.createenumattr (
    33,
    NULL,
    '@��������',
    l_encode
  );

  FOR i IN (
    SELECT
      gs.scheme,
      regexp_replace(s.name, '^@', '') AS schemename,
      gs.groupcode,
      a.code AS attrcode,
      a.name AS attrname
    FROM
      obj_attributes a,
      attr_position p,
      group_to_scheme gs,
      obj_types_schemes s
    WHERE
        a.objtype = 33
      AND
        a.name IN ('��������', '��������_2')
      AND
        p.attr = a.code
      AND
        gs.code = p.groupscheme
      AND
        s.code = gs.scheme

  ) LOOP
    pkg_sepo_system_objects.addattrtoscheme(
      i.scheme,
      i.groupcode,
      l_groupattr
    );

    l_sqlattr := REPLACE(l_sql, 'NEW', l_groupattr);
    l_sqlattr := REPLACE(l_sqlattr, 'OLD', i.attrcode);

--    Dbms_Output.put_line(l_sqlattr || ' ' || l_enval || ' ' || i.schemename);

    EXECUTE IMMEDIATE l_sqlattr USING l_enval, i.schemename;

    INSERT INTO sepo_import_log (msg)
    VALUES (
      '������� �������� � �������� "' || i.attrname || '" �� ������� "' ||
      '��������' || '" ������ ����� "' || i.schemename || '"'
    );

  END LOOP;

--  �������� ������ ���������
  FOR i IN (
    SELECT
      code,
      objtype,
      shortname
    FROM
      obj_attributes a
    WHERE
        a.name IN ('��������', '��������_2')
      AND
        a.objtype = 33
  ) LOOP
    DELETE FROM attr_position
    WHERE
        attr = i.code;

    pkg_sepo_system_objects.dropattr(i.objtype, i.shortname);

  END LOOP;

  --  ������ ������� � ����� ���������
  UPDATE obj_attributes
  SET
    name = regexp_replace(name, '^@', '')
  WHERE
      name = '@��������';

  COMMIT;

END;
/