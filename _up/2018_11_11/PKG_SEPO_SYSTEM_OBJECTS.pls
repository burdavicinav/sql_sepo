PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_system_objects
CREATE OR REPLACE PACKAGE pkg_sepo_system_objects
AS
  unsupported_oper_exception EXCEPTION;

  -- константы
  detail CONSTANT NUMBER := 2;
  fixture_node CONSTANT NUMBER := 31;
  fixture CONSTANT NUMBER := 32;
  std_fixture CONSTANT NUMBER := 33;

  -- создание перечисления
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

  -- создание атрибута на основе перечисления
  FUNCTION CreateEnumAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE,
    p_name obj_attributes.name%TYPE,
    p_enum_code NUMBER
  )
  RETURN NUMBER;

  -- удаление атрибута
  PROCEDURE DropAttr(
    p_type NUMBER,
    p_shortname obj_attributes.shortname%TYPE
  );

  -- создание группы
  FUNCTION CreateGroup(
    p_type NUMBER,
    p_name obj_types_groups.name%TYPE
  )
  RETURN NUMBER;

  -- создание схемы
  FUNCTION CreateScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE,
    p_isdefault obj_types_schemes.is_default%TYPE,
    p_notice obj_types_schemes.notice%TYPE := NULL
  )
  RETURN NUMBER;

  -- удаление схемы
  PROCEDURE dropscheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE
  );

  -- удаление всех схем объекта
  PROCEDURE dropschemes(
    p_type NUMBER
  );

  -- создание схемы по умолчанию
  FUNCTION CreateDefaultScheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE
  )
  RETURN NUMBER;

  -- удаление атрибутов из схемы
  PROCEDURE DeleteGroupsFromScheme(p_scheme_code NUMBER);

  -- добавление атрибута в схему
  PROCEDURE AddAttrToScheme(
    p_scheme_code NUMBER,
    p_group_code NUMBER,
    p_attr_code NUMBER
  );

  -- добавление зависимости схемы от заданного атрибута
  -- поддерживается зависимость только от одного атрибута и значения
  -- поддерживается только схемы стандартной оснастки
  PROCEDURE CreateSchemeFilter(
    p_scheme_code NUMBER,
    p_attr_code NUMBER,
    p_enum_value_code NUMBER
  );

  PROCEDURE setattrcalc(
    p_attr NUMBER,
    p_rule VARCHAR2 := NULL,
    p_schemedep BOOLEAN := FALSE
  );

  PROCEDURE setschemeattrrule(
    p_attr NUMBER,
    p_scheme NUMBER,
    p_group NUMBER,
    p_rule VARCHAR2
  );

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_system_objects
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
    l_value_size NUMBER;
    l_ddl VARCHAR2(1000);
  BEGIN

    IF p_attr_type = 1 THEN
      l_value_size := 255;

    ELSE
      l_value_size := 0;

    END IF;

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
      NULL, SYSDATE, l_value_type, l_value_size, 0, NULL,
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
    l_iscalc NUMBER;
    l_table NUMBER;
    l_tblchr VARCHAR2(5);
  BEGIN
    SELECT
      Max(code),
      Max(is_calculated),
      Max(table_number)
    INTO
      l_attr_code,
      l_iscalc,
      l_table
    FROM
      obj_attributes
    WHERE
        objtype = p_type
      AND
        shortname = p_shortname;

    IF l_attr_code IS NOT NULL THEN
      IF l_table > 1 THEN
        l_tblchr := '_' || To_Char(l_table);

      ELSE
        l_tblchr := '';

      END IF;

      DELETE FROM obj_attributes WHERE code = l_attr_code;

      EXECUTE IMMEDIATE 'alter table obj_attr_values_' || p_type || l_tblchr ||
        ' drop column a_' || l_attr_code;

      IF l_iscalc IN (1,2) THEN
        EXECUTE IMMEDIATE 'alter table obj_attr_values_' || p_type || l_tblchr ||
        ' drop column a_' || l_attr_code || '_is_calc';

      END IF;

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

  PROCEDURE dropscheme(
    p_type NUMBER,
    p_name obj_types_schemes.name%TYPE
  )
  IS
  BEGIN
    DELETE FROM obj_types_schemes WHERE objtype = p_type AND name = p_name;
  END;

  PROCEDURE dropschemes(
    p_type NUMBER
  )
  IS

  BEGIN
    FOR i IN (SELECT name FROM obj_types_schemes WHERE objtype = 33) LOOP
      dropscheme(p_type, i.name);
    END LOOP;

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
    -- константы
    l_version_count := 52;
    l_version := 'VersionSupport_3D03138E_BDC1_4A1E_A3BF_D183098F3772';
    l_import_count := 16;
    l_import := 'Импорт оснастки';

    l_count_attrs := 1;
    l_count_values := 1;

    -- удаление текущих данных
    DELETE FROM obj_deciding_scheme_filter
    WHERE
        scheme = p_scheme_code;

    DELETE FROM scheme_deciding_attrs
    WHERE
        scheme = p_scheme_code;

    -- создание фильтра
    Dbms_Lob.createtemporary(l_blob, TRUE);
    Dbms_Lob.OPEN(l_blob, Dbms_Lob.lob_readwrite);

    -- количество байтов в номере версии
    l_raw := pkg_sepo_raw_operations.getbytes(l_version_count);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- номер версии
    l_raw := pkg_sepo_raw_operations.getbytes(l_version);
    Dbms_Lob.writeappend(l_blob, l_version_count, l_raw);

    -- число 1, 4 байта
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- количество байтов, 4 байта
    l_raw := pkg_sepo_raw_operations.getbytes(l_import_count);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- константа - "импорт оснастки"
    l_raw := pkg_sepo_raw_operations.getbytes(l_import);
    Dbms_Lob.writeappend(l_blob, l_import_count, l_raw);

    -- количество атрибутов
    l_raw := pkg_sepo_raw_operations.getbytes(l_count_attrs);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- код атрибута
    l_raw := pkg_sepo_raw_operations.getbytes(p_attr_code);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- число 1, 4 байта
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- тип атрибута, 4 байта
    l_raw := pkg_sepo_raw_operations.getbytes(10);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- 1 неизвестный байт
    l_raw := pkg_sepo_raw_operations.getbytes(1);
    Dbms_Lob.writeappend(l_blob, 1, l_raw);

    -- количество значений атрибута, 4 байта
    l_raw := pkg_sepo_raw_operations.getbytes(l_count_values);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- значение перечисления
    l_raw := pkg_sepo_raw_operations.getbytes(p_enum_value_code);
    Dbms_Lob.writeappend(l_blob, 4, l_raw);

    -- обвноление фильтра
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

  PROCEDURE setattrcalc(
    p_attr NUMBER,
    p_rule VARCHAR2 := NULL,
    p_schemedep BOOLEAN := FALSE
  )
  IS
    l_iscalc NUMBER;
    l_rulecode NUMBER;
  BEGIN
    SELECT
      is_calculated
    INTO
      l_iscalc
    FROM
      obj_attributes
    WHERE
        code = p_attr;

    IF l_iscalc = 0 THEN
      UPDATE obj_attributes
      SET
        is_calculated = 2
      WHERE
          code = p_attr;

      EXECUTE IMMEDIATE 'alter table obj_attr_values_33' ||
        ' add a_' || p_attr || '_is_calc number default 1';

      IF p_schemedep THEN
        INSERT INTO obj_calc_info (
          code, formula_code, stored, editable, float_formula, decide_attr,
          force_recalc, sheme_dependent_formula, autocalc, value_allways_fixed
        )
        VALUES (
          p_attr, NULL, 1, 1, 0, NULL,
          0, 1, 1, 0
        );

      ELSE
        IF p_rule IS NOT NULL THEN
          l_rulecode := sq_compute_formula.NEXTVAL;

          INSERT INTO compute_formula (
            code, rulecode, name, shortname, ordernum, hidden, converted,
            relative, actual
          )
          VALUES (
            l_rulecode, 1000000066, NULL, NULL, 0, 1, 1,
            0, 0
          );

          INSERT INTO formulas (
            code, formula
          )
          VALUES (
            l_rulecode, p_rule
          );

        END IF;

        INSERT INTO obj_calc_info (
          code, formula_code, stored, editable, float_formula, decide_attr,
          force_recalc, sheme_dependent_formula, autocalc, value_allways_fixed
        )
        VALUES (
          p_attr, l_rulecode, 1, 1, 0, NULL,
          0, 0, 1, 0
        );

      END IF;

    ELSIF l_iscalc = 1 THEN
      RAISE unsupported_oper_exception;

    ELSE
      IF p_schemedep THEN
        UPDATE obj_calc_info
        SET
          formula_code = NULL,
          sheme_dependent_formula = 1
        WHERE
            code = p_attr;

      ELSE
        IF p_rule IS NOT NULL THEN
          l_rulecode := sq_compute_formula.NEXTVAL;

          INSERT INTO compute_formula (
            code, rulecode, name, shortname, ordernum, hidden, converted,
            relative, actual
          )
          VALUES (
            l_rulecode, 1000000066, NULL, NULL, 0, 1, 1,
            0, 0
          );

          INSERT INTO formulas (
            code, formula
          )
          VALUES (
            l_rulecode, p_rule
          );

        END IF;

        UPDATE obj_calc_info SET formula_code = l_rulecode WHERE code = p_attr;

      END IF;

    END IF;

  END;

  PROCEDURE setschemeattrrule(
    p_attr NUMBER,
    p_scheme NUMBER,
    p_group NUMBER,
    p_rule VARCHAR2
  )
  IS
    l_rulename compute_formula.name%TYPE;
    l_rule_shortname compute_formula.shortname%TYPE;
    l_shortname obj_attributes.shortname%TYPE;
    l_rulecode NUMBER;
  BEGIN
    SELECT
      shortname
    INTO
      l_shortname
    FROM
      obj_attributes
    WHERE
        code = p_attr;

    l_rulename := 'Формула атрибута в схеме: ' || l_shortname;
    l_rule_shortname := 'ФАС_' || l_shortname;

    setattrcalc(p_attr, NULL, TRUE);
    addattrtoscheme(p_scheme, p_group, p_attr);

    IF p_rule IS NOT NULL THEN
      l_rulecode := sq_compute_formula.NEXTVAL;

      INSERT INTO compute_formula (
        code, rulecode, name, shortname, ordernum, hidden, converted,
        relative, actual
      )
      VALUES (
        l_rulecode, 1000000066, l_rulename, l_rule_shortname, 0, 1, 1,
        0, 0
      );

      INSERT INTO formulas (
        code, formula
      )
      VALUES (
        l_rulecode, p_rule
      );

    END IF;

    INSERT INTO obj_formula_to_sheme (
      code, calc_info, formula, sheme
    )
    VALUES (
      sq_obj_formula_to_sheme.NEXTVAL, p_attr, l_rulecode, p_scheme
    );

  END;

END;
/

