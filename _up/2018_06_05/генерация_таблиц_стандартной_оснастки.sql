-- удаление сгенерированных таблиц
BEGIN
  FOR i IN (SELECT * FROM sepo_std_tables) LOOP
    EXECUTE IMMEDIATE 'drop table sepo_' || i.f_table;
  END LOOP;
END;
/

-- для проверки и тестирования

-- создание таблиц и заполнение
-- не стал оформлять в виде процедуры, так как для выполнения необходимо будет
-- давать прямые права omp_adm на создание объектов
DECLARE
  TYPE field IS RECORD (name VARCHAR2(100), value_ VARCHAR2(200));
  TYPE field_list IS TABLE OF field;
  l_fl field_list;

  l_sql VARCHAR2(1000);
  l_key NUMBER;
  l_prev_record NUMBER;

  l_cursor NUMBER := Dbms_Sql.open_cursor;
  l_result NUMBER;
BEGIN
  FOR k IN (
    SELECT
      *
    FROM
      sepo_std_tables
  ) LOOP
    l_sql := 'create table sepo_' || k.f_table;
    l_sql := l_sql || '(f_key number,';

    FOR i IN (
      SELECT
        f.field
      FROM
        sepo_std_table_fields f
      WHERE
          f.id_table = k.id
      ORDER BY
        To_Number(regexp_replace(f.field, '\D', ''))
    ) LOOP
      l_sql := l_sql || i.field || ' varchar2(200),';

    END LOOP;

    l_sql := SubStr(l_sql, 1, Length(l_sql) - 1);
    l_sql := l_sql || ')';

--    Dbms_Output.put_line(l_sql);

    EXECUTE IMMEDIATE l_sql;

    FOR i IN (
      SELECT
        id,
        f_key
      FROM
        sepo_std_table_records
      WHERE
          id_table = k.id
    ) LOOP
      l_fl := field_list();

      l_fl.extend();
      l_fl(1).name := 'f_key';
      l_fl(1).value_ := i.f_key;

      FOR j IN (
        SELECT
          f.field,
          c.field_value
        FROM
          sepo_std_table_rec_contents c,
          sepo_std_table_fields f
        WHERE
            c.id_field = f.id
          AND
            c.id_record = i.id
      ) LOOP
        l_fl.extend();
        l_fl(l_fl.Count()).name := j.field;
        l_fl(l_fl.Count()).value_ := j.field_value;

      END LOOP;

      l_sql := 'insert into sepo_' || k.f_table || '(';

      FOR j IN 1..l_fl.Count() LOOP
        l_sql := l_sql || l_fl(j).name;
        IF j < l_fl.Count() THEN l_sql := l_sql || ','; END IF;

      END LOOP;

      l_sql := l_sql || ') values (';

      FOR j IN 1..l_fl.count() LOOP
        l_sql := l_sql || ':param_' || j;
        IF j < l_fl.Count() THEN l_sql := l_sql || ','; END IF;

      END LOOP;

      l_sql := l_sql || ')';

      l_cursor := Dbms_Sql.open_cursor;
      dbms_sql.parse(l_cursor, l_sql, dbms_sql.native);

      FOR j IN 1..l_fl.count() LOOP
        dbms_sql.bind_variable(l_cursor, ':param_' || j, l_fl(j).value_);

      END LOOP;

      l_result := dbms_sql.execute(l_cursor);
      dbms_sql.close_cursor(l_cursor);

    END LOOP;


  END LOOP;

END;
/

-- примеры
SELECT * FROM sepo_tbl000455;
SELECT * FROM sepo_tbl000490;
SELECT * FROM sepo_tbl011197;