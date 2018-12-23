/* ����� ��������� ��� ������ � ���������� */
/*
�������� �� ��������� �����:

Init �������������� ������ ����������,
������������� ��� ������� �������;

AddAttrData � ����������� �� ���� �������� ��������
��������� ������� � ������ ��� ������������ ����������;

UpdateAttrs �� ������ ��������� ������� ���������
��������� ������������ sql-������ � ����� �����������
� ������� ������ dbms_sql ��� ��������� p_objCode -
omp_objects.code

*/
CREATE OR REPLACE PACKAGE pkg_sepo_attr_operations
IS
  /* ��� ������� ������� */
  pkg_obj_type NUMBER;

  /* ������������ ���� �������� ��������� */
  ATTR_TYPE_STRING CONSTANT NUMBER := 1;
  ATTR_TYPE_DOUBLE CONSTANT NUMBER := 2;
  ATTR_TYPE_INT CONSTANT NUMBER := 3;
  ATTR_TYPE_DATE CONSTANT NUMBER := 4;
  ATTR_TYPE_LINK CONSTANT NUMBER := 6;

  /* ����� �������� */
  PROCEDURE Clear;

  /* ������������� �������� */
  PROCEDURE Init( p_obj_type NUMBER );

  /* ��������� �������� �������� */
  /* ��� ����������: ��� �����, ������ � ���� */
  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value NUMBER,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  );

  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value VARCHAR2,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  );

  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value DATE,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  );

  /* ���������� �������� ��������� �� ��������� ���� */
  PROCEDURE UpdateAttrs( p_objCode NUMBER );

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT NUMBER
  );

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT VARCHAR2
  );

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT DATE
  );

  PROCEDURE AddAttrFind(
    p_object_type NUMBER,
    p_name_attr obj_attributes.shortName%TYPE,
    p_type_attr NUMBER,
    p_sql_reset BOOLEAN := FALSE
  );

  /*
  PROCEDURE Find (
    p_name obj_attributes.name%TYPE,
    p_type NUMBER,
    p_filter NUMBER,
    p_findCount OUT NUMBER

  );
  */
  PROCEDURE Find (
    p_filter VARCHAR2,
    p_findCount OUT NUMBER

  );

  FUNCTION NextItem RETURN NUMBER;

  -- �������� ������������� ��������� ��� �������� �������� �������
  PROCEDURE CreateAttrView(p_viewName VARCHAR2, p_objType NUMBER );

END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_attr_operations
IS
  /* ��������� ��������� */
  TYPE tp_attr_data IS RECORD (
    codeAttr NUMBER, -- ��� �������� � ��
    nameAttr obj_attributes.shortName%type, -- ��� ��������
    typeAttr NUMBER, -- ��� ��������
    valueAttr AnyData, -- �������� ��������
    isMeasExists NUMBER, -- ������� ���������
    valueMeas measures.name%TYPE, -- �������� ������� ��������� ( ���� ���� )
    calcType NUMBER,
    valueCalc NUMBER
  );

  /* ��� ���� ������� ������� */
  pkg_obj_name obj_types.name%TYPE;

  /* ������ ��������� */
  TYPE tp_attr_data_list IS TABLE OF tp_attr_data;

  /* ������� */
  pkg_data tp_attr_data;
  /* ������ ��������� */
  pkg_listData tp_attr_data_list;

  /* ������� ������ ������ ��������� */
  pkg_currentIndex NUMBER;

  /* ��� ������ �� �������� ��������� */
  TYPE tp_list_find_values IS TABLE OF NUMBER;
  pkg_list_find_values tp_list_find_values;
  pkg_find_value_index NUMBER;

  pkg_sqlFind VARCHAR2(1000);
  pkg_attrFindCount NUMBER;
  /**/

  PROCEDURE ClearFindData
  IS

  BEGIN
    pkg_list_find_values := NULL;
    pkg_find_value_index := 0;

  END;

  /* ����� ���� ������������� �������� */
  PROCEDURE Clear
  IS

  BEGIN
    pkg_data := NULL;
    pkg_obj_type := NULL;
    pkg_obj_name := NULL;
    pkg_currentIndex := 0;
    pkg_listData := NULL;

  END;

  /* ������������� ������ */
  PROCEDURE Init ( p_obj_type NUMBER )
  IS

  BEGIN
    Clear();

    pkg_data := NULL;
    pkg_obj_type := p_obj_type;
    pkg_currentIndex := 0;
    pkg_listData := tp_attr_data_list();

    /* ����������� ������������ ���� ������� ������� */
    SELECT name INTO pkg_obj_name FROM obj_types WHERE code = p_obj_type;

  END;

  /* ������ �������� �������� � ��������� � ������ */
  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value NUMBER,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  )
  IS

  BEGIN
    pkg_data.codeAttr := NULL;
    pkg_data.isMeasExists := NULL;
    pkg_data.nameAttr := p_name;
    pkg_data.typeAttr := p_type;
    pkg_data.valueAttr := AnyData.ConvertNumber( p_value );
    pkg_data.valueMeas := p_meas;
    pkg_data.valueCalc := p_calc;

    pkg_listData.extend();
    pkg_currentIndex := pkg_currentIndex + 1;
    pkg_listData(pkg_currentIndex) := pkg_data;

  END;

  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value VARCHAR2,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  )
  IS

  BEGIN
    pkg_data.codeAttr := NULL;
    pkg_data.isMeasExists := NULL;
    pkg_data.nameAttr := p_name;
    pkg_data.typeAttr := p_type;
    pkg_data.valueAttr := AnyData.ConvertVarchar2( p_value );
    pkg_data.valueMeas := p_meas;
    pkg_data.valueCalc := p_calc;

    pkg_listData.extend();
    pkg_currentIndex := pkg_currentIndex + 1;
    pkg_listData(pkg_currentIndex) := pkg_data;

  END;

  PROCEDURE AddAttrData(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_value DATE,
    p_meas measures.name%TYPE DEFAULT NULL,
    p_calc NUMBER DEFAULT NULL
  )
  IS

  BEGIN
    pkg_data.codeAttr := NULL;
    pkg_data.isMeasExists := NULL;
    pkg_data.nameAttr := p_name;
    pkg_data.typeAttr := p_type;
    pkg_data.valueAttr := AnyData.ConvertDate( p_value );
    pkg_data.valueMeas := p_meas;
    pkg_data.valueCalc := p_calc;

    pkg_listData.extend();
    pkg_currentIndex := pkg_currentIndex + 1;
    pkg_listData(pkg_currentIndex) := pkg_data;

  END;

  /* ���������� ��������� */
  /* ��������� ��� � ��� ������� ������� */
  PROCEDURE UpdateAttrs( p_objCode NUMBER )
  IS
    /* ������ ������� �� ���������� */
    l_sqlUpdate VARCHAR2(1000);

    /* ������ ��������� ���������� */
    TYPE bindList IS RECORD( type_ NUMBER, value_ AnyData );
    TYPE list IS TABLE OF bindList;
    l_params list;
    l_paramIndex NUMBER;

    /* ��� �������� ���������� ������������ ����������� �����
    Oracle - dbms_sql */
    l_cursor NUMBER := Dbms_Sql.open_cursor;
    l_result NUMBER;

    /* �������� ������� ��������� ��� �������� */
    l_measCode NUMBER;

    l_bind NUMBER;
    /* ������������ ��� �������� �������� � ������� */
    l_ret_number NUMBER; -- ��� �����
    l_ret_varchar2 VARCHAR2(255); -- ��� �����
    l_ret_date DATE; -- ��� ���

    l_current_attr obj_attributes.shortName%TYPE;

    l_count NUMBER;
    /* Exceptions */
    l_attr_not_exists EXCEPTION; -- � ������, ���� �� ������ �������
    l_unit_not_exists EXCEPTION; -- � ������, ���� �� ������� �������� ���������
    -- ��� ��������
    /* */

  BEGIN
    /* ������������� ������ ��������� ���������� */
    l_params := list();
    l_paramIndex := 0;

    /* ������ ������������� �������... */
    l_sqlUpdate := 'UPDATE obj_attr_values_' || pkg_obj_type || ' SET ';

    /* ���� �� ������ ���������, ������� � ���������� */
    FOR i IN 1..pkg_listData.Count() LOOP
      /* ������� ������� */
      l_current_attr := pkg_listData(i).nameAttr;

      /* ��������� ������������� ��������...  */
      SELECT
        Count(*)
      INTO
        l_count
      FROM
        obj_attributes data
      WHERE
          data.objType = pkg_obj_type
        AND
          data.shortName = pkg_listData(i).nameAttr
        AND
          data.value_type = pkg_listData(i).typeAttr;

      /* ���� ���, �� ������ */
      IF l_count = 0 THEN RAISE l_attr_not_exists; END IF;

      /* ��������� ���� �������� � ������� � ���� ������� ��������� */
      SELECT
        data.code,
        varMeas,
        is_calculated
      INTO
        pkg_listData(i).codeAttr,
        pkg_listData(i).isMeasExists,
        pkg_listData(i).calcType
      FROM
        obj_attributes data
      WHERE
          data.objType = pkg_obj_type
        AND
          data.shortName = pkg_listData(i).nameAttr
        AND
          data.value_type = pkg_listData(i).typeAttr;

      /* � ������������ ������� ����������� ��������� ����������,
      � �� �������� ������������ � ������ */
      l_paramIndex := l_paramIndex + 1;
      l_sqlUpdate := l_sqlUpdate || 'A_' || pkg_listData(i).codeAttr || '=:param_' || l_paramIndex;

      l_params.extend();
      l_params(l_paramIndex).type_ := pkg_listData(i).typeAttr;
      l_params(l_paramIndex).value_ := pkg_listData(i).valueAttr;

      /* ���� � �������� ���� ������� ���������, ��...*/
      IF pkg_listData(i).isMeasExists = 1 THEN
        l_measCode := NULL;

        /* �������� ��� �� �� ������������ ������� ��������� */
        IF pkg_listData(i).valueMeas IS NOT NULL THEN
          SELECT
            Count(*)
          INTO
            l_count
          FROM
            measures
          WHERE
            name = pkg_listData(i).valueMeas;

          /* ���� �������� ������� ��������� �� �������, �� ������... */
          IF l_count = 0 THEN RAISE l_unit_not_exists; END IF;

          SELECT
            code
          INTO
            l_measCode
          FROM
            measures
          WHERE
            name = pkg_listData(i).valueMeas;

        END IF;

        /* ��� �������� ������� ��������� ����� ��������� ��������� ���������� */
        l_paramIndex := l_paramIndex + 1;
        l_sqlUpdate := l_sqlUpdate || ',M_' || pkg_listData(i).codeAttr || '=:param_' || l_paramIndex;

        l_params.extend();
        l_params(l_paramIndex).type_ := ATTR_TYPE_INT;
        l_params(l_paramIndex).value_ := anyData.ConvertNumber(l_measCode);

      END IF;

      IF pkg_listData(i).valueCalc IN (1,2) THEN
        l_paramIndex := l_paramIndex + 1;
        l_sqlUpdate := l_sqlUpdate || ',A_' || pkg_listData(i).codeAttr
          || '_IS_CALC=:param_' || l_paramIndex;

        l_params.extend();
        l_params(l_paramIndex).type_ := ATTR_TYPE_INT;
        l_params(l_paramIndex).value_ := anyData.ConvertNumber(pkg_listData(i).valueCalc);

      END IF;

      IF i < pkg_listData.Count() THEN l_sqlUpdate := l_sqlUpdate || ','; END IF;


    END LOOP;

    /* ��������������� ��������� ����������� ���������� - ��� ������� ������� */
    l_paramIndex := l_paramIndex + 1;
    l_sqlUpdate := l_sqlUpdate || ' WHERE soCode=:param_' || l_paramIndex;

    l_params.extend();
    l_params(l_paramIndex).type_ := ATTR_TYPE_INT;
    l_params(l_paramIndex).value_ := anyData.ConvertNumber(p_objCode);

--    Dbms_Output.put_line( sqlUpdate );

    /* �� ���� ����� ������ ������� ������.
    ���������� ���������������� ������ � ���������� �������� ���������� */
    /* ������ ������� */
    dbms_sql.parse( l_cursor, l_sqlUpdate, dbms_sql.native );

    /* ���� �� ���������� ����������. ���������� ��������������� ��������
    � ������������� � ������... */
    FOR l_index IN 1..l_params.Count() LOOP

      /* ...� ����������� �� ���� �������� */
      IF l_params(l_index).type_ IN ( ATTR_TYPE_INT, ATTR_TYPE_DOUBLE, ATTR_TYPE_LINK ) THEN
        l_bind := l_params(l_index).value_.GetNumber( l_ret_number );
        dbms_sql.bind_variable( l_cursor, ':param_' || l_index, l_ret_number );

      ELSIF l_params(l_index).type_ IN ( ATTR_TYPE_STRING ) THEN
        l_bind := l_params(l_index).value_.GetVarchar2( l_ret_varchar2 );
        dbms_sql.bind_variable( l_cursor, ':param_' || l_index, l_ret_varchar2 );

      ELSIF l_params(l_index).type_ IN ( ATTR_TYPE_DATE ) THEN
        l_bind := l_params(l_index).value_.GetDate( l_ret_date );
        dbms_sql.bind_variable( l_cursor, ':param_' || l_index, l_ret_date );

      END IF;


    END LOOP;

    /* ���������� ������������� ������� */
    l_result := dbms_sql.execute( l_cursor );
    dbms_sql.close_cursor( l_cursor );

  EXCEPTION
    WHEN l_attr_not_exists THEN
      Raise_Application_Error ( -20101, '������! �������� ' || l_current_attr ||
        ' �� ������� '|| pkg_obj_name || ' �� ���������� ��� ������� ����� ���!' );

    WHEN l_unit_not_exists THEN
      Raise_Application_Error( -20102,
        '������! ��� ������� ������� ��������� �������� ��������� ������!' );

    WHEN OTHERS THEN
--      Dbms_Output.put_line(l_sqlUpdate);
      RAISE;

  END;

  PROCEDURE QueryForRead(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_sql OUT VARCHAR2
  )
  IS
    l_attr_code NUMBER;

  BEGIN
    SELECT
      data.code
    INTO
      l_attr_code
    FROM
      obj_attributes data

    WHERE
        data.objType = pkg_obj_type
      AND
        data.shortName = p_name
      AND
        data.value_type = p_type;

    p_sql := 'SELECT A_' || l_attr_code ||
      ' FROM obj_attr_values_' || pkg_obj_type ||
      ' WHERE soCode = :1';

  END;

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT NUMBER
  )
  IS
    l_sql VARCHAR2(100);

  BEGIN
    QueryForRead( p_name, p_type, l_sql );
    EXECUTE IMMEDIATE l_sql INTO p_value USING p_objectCode;

  END;

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT VARCHAR2
  )
  IS
    l_sql VARCHAR2(100);

  BEGIN
    QueryForRead( p_name, p_type, l_sql );
    EXECUTE IMMEDIATE l_sql INTO p_value USING p_objectCode;

  END;

  PROCEDURE Read_(
    p_name obj_attributes.shortName%TYPE,
    p_type NUMBER,
    p_objectCode NUMBER,
    p_value OUT DATE
  )
  IS
    l_sql VARCHAR2(100);

  BEGIN
    QueryForRead( p_name, p_type, l_sql );
    EXECUTE IMMEDIATE l_sql INTO p_value USING p_objectCode;

  END;

  PROCEDURE AddAttrFind(
    p_object_type NUMBER,
    p_name_attr obj_attributes.shortName%TYPE,
    p_type_attr NUMBER,
    p_sql_reset BOOLEAN := FALSE
  )

  IS
    l_attr_code NUMBER;

  BEGIN
    SELECT
      data.code
    INTO
      l_attr_code
    FROM
      obj_attributes data

    WHERE
        data.objType = p_object_type
      AND
        data.shortName = p_name_attr
      AND
        data.value_type = p_type_attr;

    IF p_sql_reset THEN
      pkg_sqlFind := '';
      pkg_attrFindCount := 0;

    END IF;

    pkg_attrFindCount := pkg_attrFindCount + 1;

    pkg_sqlFind := pkg_sqlFind ||
      CASE
        WHEN pkg_attrFindCount > 1 THEN ' UNION '
        ELSE ''
      END ||

      'SELECT soCode FROM obj_attr_values_' || p_object_type ||
      ' WHERE A_' || l_attr_code || ' = :param_' || pkg_attrFindCount;

  END;

  PROCEDURE Find (
    p_filter VARCHAR2,
    p_findCount OUT NUMBER
  )
  IS
    l_cursor NUMBER := Dbms_Sql.open_cursor;
    l_result NUMBER;
    l_soCode NUMBER;

  BEGIN
    ClearFindData();

    pkg_list_find_values := tp_list_find_values();

    dbms_sql.parse( l_cursor, pkg_sqlFind, dbms_sql.native );
    FOR i IN 1..pkg_attrFindCount LOOP
      dbms_sql.bind_variable( l_cursor, ':param_' || i, p_filter );

    END LOOP;

    DBMS_SQL.define_column(l_cursor, 1, l_soCode);
    l_result := dbms_sql.execute( l_cursor );

    LOOP
      l_result := Dbms_Sql.fetch_rows(l_cursor);
      EXIT WHEN l_result = 0;

      Dbms_Sql.column_value(l_cursor, 1, l_soCode);

      pkg_list_find_values.extend();
      pkg_list_find_values(pkg_list_find_values.Count() ) := l_soCode;

    END LOOP;

    p_findCount := pkg_list_find_values.Count();
    dbms_sql.close_cursor( l_cursor );

  END;

  FUNCTION NextItem RETURN NUMBER
  IS
  BEGIN
    IF pkg_find_value_index <= pkg_list_find_values.Count() THEN
      pkg_find_value_index := pkg_find_value_index + 1;
      RETURN pkg_list_find_values( pkg_find_value_index );

    ELSE
      RETURN -1;

    END IF;

  END;

  PROCEDURE CreateAttrView(p_viewName VARCHAR2, p_objType NUMBER )
  IS
    TYPE attrLibrary IS TABLE OF NUMBER INDEX BY obj_attributes.shortName%TYPE;
    l_attrLib attrLibrary;
    l_attr obj_attributes.shortName%TYPE;

    l_sqlQuery VARCHAR2(1000);
  BEGIN
    l_attrLib.DELETE;

    -- �������� ������������� � ������
    FOR i IN (
      SELECT
        *
      FROM
        obj_attributes
      WHERE
          objType = p_objType
        AND
          shortName LIKE '%CEN%'
    ) LOOP
      l_attrLib(i.shortName) := i.code;

    END LOOP;

    l_sqlQuery :=
      'CREATE OR REPLACE VIEW ' || p_viewName || ' AS ' ||
      'SElECT soCode';

    IF l_attrLib.Count > 0 THEN
      l_sqlQuery := l_sqlQuery || ',';

      l_attr := l_attrLib.first;

      LOOP
        l_sqlQuery := l_sqlQuery || 'A_' || l_attrLib(l_attr) ||
          ' AS ' || l_attr;

        IF l_attr != l_attrLib.last THEN
          l_sqlQuery := l_sqlQuery || ',';

        ELSE
          EXIT;

        END IF;

        l_attr := l_attrLib.NEXT(l_attr);

      END LOOP;

    END IF;

    l_sqlQuery := l_sqlQuery || ' FROM obj_attr_values_' || p_objType;

    EXECUTE IMMEDIATE l_sqlQuery;

  END;

END;
/