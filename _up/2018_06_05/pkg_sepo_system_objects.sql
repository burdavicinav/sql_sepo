CREATE OR REPLACE PACKAGE pkg_sepo_system_objects
AS
  -- ���������
  detail CONSTANT NUMBER := 2;
  fixture_node CONSTANT NUMBER := 31;
  fixture CONSTANT NUMBER := 32;
  std_fixture CONSTANT NUMBER := 33;

  -- �������� ������������
  FUNCTION CreateEnumeration(p_enum_name obj_enumerations_values.name%TYPE)
  RETURN NUMBER;

  FUNCTION CreateAttr(
    p_type NUMBER,
    p_attr_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE,
    p_name obj_attributes.name%TYPE,
    p_enum_code NUMBER := NULL
  )
  RETURN NUMBER;

  -- �������� �������� �� ������ ������������
  FUNCTION CreateEnumAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE,
    p_name obj_attributes.name%TYPE,
    p_enum_code NUMBER
  )
  RETURN NUMBER;

  -- �������� ��������
  PROCEDURE DropAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE
  );

  -- �������� ������
  FUNCTION CreateGroup(
    p_type NUMBER,
    p_name obj_types_groups.name%TYPE
  )
  RETURN NUMBER;

  -- �������� �����
  FUNCTION CreateScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE,
    p_isdefault obj_types_schemes.is_default%TYPE,
    p_notice obj_types_schemes.notice%TYPE := NULL
  )
  RETURN NUMBER;

  -- �������� ����� �� ���������
  FUNCTION CreateDefaultScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE
  )
  RETURN NUMBER;

  -- �������� ��������� �� �����
  PROCEDURE DeleteGroupsFromScheme(p_scheme_code NUMBER);

  -- ���������� �������� � �����
  PROCEDURE AddAttrToScheme(
    p_scheme_code NUMBER,
    p_group_code NUMBER,
    p_attr_code NUMBER
  );

  -- ���������� ����������� ����� �� ��������� ��������
  -- �������������� ����������� ������ �� ������ �������� � ��������
  -- �������������� ������ ����� ����������� ��������
  PROCEDURE CreateSchemeFilter(
    p_scheme_code NUMBER,
    p_attr_code NUMBER,
    p_enum_value_code NUMBER
  );

END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_system_objects
AS
  FUNCTION CreateEnumeration(p_enum_name obj_enumerations_values.name%TYPE)
  RETURN NUMBER
  IS
    l_enum_code NUMBER;
  BEGIN
    l_enum_code := sq_obj_enumerations.NEXTVAL;

    INSERT INTO obj_enumerations (
      code, userenum, name, notice, numbered,
      illustrated, value_display_mode, value_edit_mode
    )
    VALUES (
      l_enum_code, 0, p_enum_name, NULL, 0,
      NULL, 0, 0
    );

    RETURN l_enum_code;

  END;

  FUNCTION CreateAttr(
    p_type NUMBER,
    p_attr_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE,
    p_name obj_attributes.name%TYPE,
    p_enum_code NUMBER := NULL
  )
  RETURN NUMBER
  IS
    l_attr_code NUMBER;
    l_value_type NUMBER;
    l_ddl VARCHAR2(1000);
  BEGIN
    IF p_attr_type IN (1, 2, 3, 4) THEN
      l_value_type := p_attr_type;

    ELSIF p_attr_type = 10 THEN
      l_value_type := 5;

    ELSE
      l_value_type := NULL;

    END IF;

    SELECT sq_obj_attributes.NEXTVAL INTO l_attr_code FROM dual;

    INSERT INTO obj_attributes (
      code, objtype, attr_type, shortname, name, is_mandatory, is_readonly,
      description, rdate, value_type, value_size, is_countable, varmeas,
      meascode, meas_depend_attr, ismultiple, is_calculated, only_in_scheme,
      is_unique, table_number, can_hide_attr, is_needinput,
      load_if_not_in_scheme, is_internal
    )
    VALUES (
      l_attr_code, p_type, p_attr_type, Nvl(p_shortname, l_attr_code), p_name, 0, 0,
      NULL, SYSDATE, l_value_type, 0, 0, NULL,
      NULL, NULL, 0, 0, 0,
      0, 1, 0, 0,
      0, 0
    );

    IF p_attr_type = 10 AND p_enum_code IS NOT NULL THEN
      INSERT INTO obj_enum_prop (
        code, defval
      )
      VALUES (
        l_attr_code, NULL
      );

      INSERT INTO obj_enum_info (
        code, encode, useconditions, all_values_if_no_conditions_ma
      )
      VALUES (
        l_attr_code, p_enum_code, 0, 0
      );

      l_ddl := 'alter table obj_attr_values_' || p_type ||
        ' add a_' || l_attr_code || ' integer null';

      EXECUTE IMMEDIATE l_ddl;

      l_ddl := 'alter table obj_attr_values_' || p_type || ' add constraint ' ||
        'fk_objenval_objav' || l_attr_code || ' foreign key (a_' ||
        l_attr_code || ') references obj_enumerations_values(code)';

      EXECUTE IMMEDIATE l_ddl;

    ELSIF p_attr_type = 1 THEN
      INSERT INTO obj_char_prop (
        code, maxlen
      )
      VALUES (
        l_attr_code, 255
      );

      l_ddl := 'alter table obj_attr_values_' || p_type ||
        ' add a_' || l_attr_code || ' varchar2(255) null';

      EXECUTE IMMEDIATE l_ddl;

    ELSIF p_attr_type = 2 THEN
      INSERT INTO obj_float_prop (
        code, aftercomma, trunc_trail_zeros
      )
      VALUES (
        l_attr_code, 6, 1
      );

      l_ddl := 'alter table obj_attr_values_' || p_type ||
        ' add a_' || l_attr_code || ' number(32,12) null';

      EXECUTE IMMEDIATE l_ddl;

    ELSIF p_attr_type = 3 THEN
      INSERT INTO obj_integer_prop (
        code
      )
      VALUES (
        l_attr_code
      );

      l_ddl := 'alter table obj_attr_values_' || p_type ||
        ' add a_' || l_attr_code || ' integer null';

      EXECUTE IMMEDIATE l_ddl;

    ELSIF p_attr_type = 4 THEN
      INSERT INTO obj_date_prop (
        code, def_init_type
      )
      VALUES (
        l_attr_code, 0
      );

      l_ddl := 'alter table obj_attr_values_' || p_type ||
        ' add a_' || l_attr_code || ' date null';

      EXECUTE IMMEDIATE l_ddl;

    END IF;

    RETURN l_attr_code;

  END;

  FUNCTION CreateEnumAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE,
    p_name obj_attributes.name%TYPE,
    p_enum_code NUMBER
  )
  RETURN NUMBER
  IS
  BEGIN
    RETURN CreateAttr(p_type, 10, p_shortname, p_name, p_enum_code);

  END;

  PROCEDURE DropAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE
  )
  IS
    l_attr_code NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_attr_code
    FROM
      obj_attributes
    WHERE
        objtype = p_type
      AND
        shortname = p_shortname;

    IF l_attr_code IS NOT NULL THEN
      DELETE FROM obj_attributes WHERE code = l_attr_code;

      EXECUTE IMMEDIATE 'alter table obj_attr_values_' || p_type ||
        ' drop column a_' || l_attr_code;

    END IF;

  END;

  FUNCTION CreateGroup(
    p_type NUMBER,
    p_name obj_types_groups.name%TYPE
  )
  RETURN NUMBER
  IS
    l_group_code NUMBER;
  BEGIN
    l_group_code := sq_obj_types_groups.NEXTVAL;

    INSERT INTO obj_types_groups (
      code, objtype, name
    )
    VALUES (
      l_group_code, p_type, p_name
    );

    RETURN l_group_code;

  END;

  FUNCTION CreateScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE,
    p_isdefault obj_types_schemes.is_default%TYPE,
    p_notice obj_types_schemes.notice%TYPE := NULL
  )
  RETURN NUMBER
  IS
    l_scheme_code NUMBER;
  BEGIN
    l_scheme_code := sq_obj_types_schemes.NEXTVAL;

    INSERT INTO obj_types_schemes (
      code, objtype, is_default, name, notice
    )
    VALUES (
      l_scheme_code, p_type, p_isdefault, p_name, p_notice
    );

    RETURN l_scheme_code;

  END;

  FUNCTION CreateDefaultScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE
  )
  RETURN NUMBER
  IS
    l_scheme_code NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_scheme_code
    FROM
      obj_types_schemes
    WHERE
        objtype = p_type
      AND
        is_default = 1;

    IF l_scheme_code IS NULL THEN
      l_scheme_code := createscheme(p_type, p_name, 1, NULL);

    ELSE
      UPDATE obj_types_schemes
      SET
        name = p_name,
        notice = NULL
      WHERE
          code = l_scheme_code;

    END IF;

    RETURN l_scheme_code;

  END;

  PROCEDURE DeleteGroupsFromScheme(p_scheme_code NUMBER)
  IS
  BEGIN
    DELETE FROM group_to_scheme
    WHERE
        scheme = p_scheme_code;
  END;

  PROCEDURE AddAttrToScheme(
    p_scheme_code NUMBER,
    p_group_code NUMBER,
    p_attr_code NUMBER
  )
  IS
    l_groupscheme NUMBER;
    l_order NUMBER;
    l_attr_exists NUMBER;
    l_attr_link NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_groupscheme
    FROM
      group_to_scheme
    WHERE
        scheme = p_scheme_code
      AND
        groupcode = p_group_code;

    IF l_groupscheme IS NULL THEN
      l_groupscheme := sq_group_to_scheme.NEXTVAL;

      SELECT
        Max(ordernum)
      INTO
        l_order
      FROM
        group_to_scheme
      WHERE
          scheme = p_scheme_code;

      INSERT INTO group_to_scheme (
        code, scheme, groupcode, ordernum
      )
      VALUES (
        l_groupscheme, p_scheme_code, p_group_code, Nvl(l_order, -1) + 1
      );

      l_attr_exists := 0;
      l_order := -1;

    ELSE
      SELECT
        Count(1)
      INTO
        l_attr_exists
      FROM
        attr_position
      WHERE
          groupscheme = l_groupscheme
        AND
          attr = p_attr_code;

      SELECT
        Max(ordernum)
      INTO
        l_order
      FROM
        attr_position
      WHERE
          groupscheme = l_groupscheme;

    END IF;

    IF l_attr_exists = 0 THEN
      l_attr_link := sq_attr_to_group.NEXTVAL;

      INSERT INTO attr_position (
        code, groupscheme, attr, ordernum, condition_formula, hidden
      )
      VALUES (
        l_attr_link, l_groupscheme, p_attr_code, Nvl(l_order, -1) + 1, NULL, 0
      );

    END IF;

  END;

  PROCEDURE CreateSchemeFilter(
    p_scheme_code NUMBER,
    p_attr_code NUMBER,
    p_enum_value_code NUMBER
  )
  IS
    l_blob BLOB;
    l_raw RAW(255);
    l_version_count NUMBER;
    l_version VARCHAR2(255);
    l_import_count NUMBER;
    l_import VARCHAR2(255);
    l_count_attrs NUMBER;
    l_attr_code NUMBER;
    l_count_values NUMBER;
    l_attr_value NUMBER;

    l_scheme_attr NUMBER;
    l_scheme_filter NUMBER;
  BEGIN
    -- ���������
    l_version_count := 52;
    l_version := 'VersionSupport_3D03138E_BDC1_4A1E_A3BF_D183098F3772';
    l_import_count := 16;
    l_import := '������ ��������';

    l_count_attrs := 1;
    l_count_values := 1;

    -- �������� ������� ������
    DELETE FROM obj_deciding_scheme_filter
    WHERE
        scheme = p_scheme_code;

    DELETE FROM scheme_deciding_attrs
    WHERE
        scheme = p_scheme_code;

    -- �������� �������
    Dbms_Lob.createtemporary(l_blob, TRUE);
    Dbms_Lob.OPEN(l_blob, Dbms_Lob.lob_readwrite);

    -- ���������� ������ � ������ ������
    l_raw := pkg_sepo_raw_operations.getbytes(l_version_count);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ����� ������
    l_raw := pkg_sepo_raw_operations.getbytes(l_version);
    Dbms_Lob.writeappend(l_blob, l_version_count, l_raw);

    -- ����� 1, 4 �����
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ���������� ������, 4 �����
    l_raw := pkg_sepo_raw_operations.getbytes(l_import_count);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ��������� - "������ ��������"
    l_raw := pkg_sepo_raw_operations.getbytes(l_import);
    Dbms_Lob.writeappend(l_blob, l_import_count, l_raw);

    -- ���������� ���������
    l_raw := pkg_sepo_raw_operations.getbytes(l_count_attrs);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ��� ��������
    l_raw := pkg_sepo_raw_operations.getbytes(p_attr_code);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ����� 1, 4 �����
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ��� ��������, 4 �����
    l_raw := pkg_sepo_raw_operations.getbytes(10);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- 1 ����������� ����
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 1, l_raw);

    -- ���������� �������� ��������, 4 �����
    l_raw := pkg_sepo_raw_operations.getbytes(l_count_values);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- �������� ������������
    l_raw := pkg_sepo_raw_operations.getbytes(p_enum_value_code);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- ���������� �������
    l_scheme_attr := sq_scheme_deciding_attrs.NEXTVAL;

    INSERT INTO scheme_deciding_attrs (
      code, scheme, attr
    )
    VALUES (
      l_scheme_attr, p_scheme_code, p_attr_code
    );

    l_scheme_filter := sq_obj_deciding_scheme_filter.NEXTVAL;

    INSERT INTO obj_deciding_scheme_filter (
      code, scheme, fltdata
    )
    VALUES (
      l_scheme_filter, p_scheme_code, l_blob
    );

    Dbms_Lob.freetemporary(l_blob);

  END;

END;
/