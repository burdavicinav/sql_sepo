PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_export_materials
CREATE OR REPLACE PACKAGE pkg_sepo_export_materials
IS
  pkg_dir CONSTANT VARCHAR2(100) := 'DBF_DIR';

  EXP_MAT_NOT_CORRECT_DM_EXCEPTION EXCEPTION;
  EXP_MAT_NOT_CORRECT_TOL_EXCEPTION EXCEPTION;

  PROCEDURE Clear;
  -- экспорт
  PROCEDURE Export;

  PROCEDURE SelectMatRow(
    p_status NUMBER,
    p_priznak NUMBER,
    p_soCode NUMBER,
    p_plCode materials.plCode%TYPE,
    p_meas_1 NUMBER,
    p_meas_2 NUMBER,
    p_meas_3 NUMBER,
    p_create_date DATE,
    p_modify_date DATE,
    p_create_user NUMBER,
    p_modify_user NUMBER
  );

  PROCEDURE SelectTmcRow(
    p_status NUMBER,
    p_priznak NUMBER,
    p_soCode NUMBER,
    p_plCode stock_other.Sign%TYPE,
    p_meas_1 NUMBER,
    p_create_date DATE,
    p_modify_date DATE,
    p_create_user NUMBER,
    p_modify_user NUMBER
  );

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_export_materials
CREATE OR REPLACE PACKAGE BODY pkg_sepo_export_materials
IS
  PROCEDURE Clear
  IS
  BEGIN
    DELETE FROM sepo_export_materials;
  END;

  -- переводит данные в BLOB для последующей загрузки в файл
  PROCEDURE BuildData(p_number_str NUMBER := 0)
  IS
    l_sysDate DATE DEFAULT SYSDATE;
    l_time VARCHAR2(8);

    k NUMBER;
  BEGIN
    l_time := To_Char(SYSDATE, 'HH24:MI:SS');

    exportToDBF.DataBeginWrite();
    k := p_number_str;

    FOR i IN (SELECT data.* FROM sepo_export_materials data) LOOP
      k := k + 1;

      exportToDBF.NewRecord();
      exportToDBF.AddField(i.MAT, 7);
      exportToDBF.AddField(i.SKL, 3);
      exportToDBF.AddField(i.POZ1, 4);
      exportToDBF.AddField(i.POZ2, 4);
      exportToDBF.AddField(i.EIO, 3);
      exportToDBF.AddField(i.GRU, 7);
      exportToDBF.AddField(Upper(i.NAIM), 20);
      exportToDBF.AddField(i.MARK, 20);
      exportToDBF.AddField(i.DIAM, 2);
      exportToDBF.AddField(i.DM, 10, 3);
      exportToDBF.AddField(i.CLT, 1);
      exportToDBF.AddField(i.TOL, 10, 3);
      exportToDBF.AddField(i.CHIR, 10, 3);
      exportToDBF.AddField(i.DL, 10, 3);
      exportToDBF.AddField(i.GOST, 30);
      exportToDBF.AddField(i.SORM, 25);
      exportToDBF.AddField(i.KOEF, 4, 2);
      exportToDBF.AddField(i.EID1, 3);
      exportToDBF.AddField(i.UDN1, 8, 3);
      exportToDBF.AddField(i.EID2, 3);
      exportToDBF.AddField(i.UDN2, 8, 3);
      exportToDBF.AddField(i.VED, 2);
      exportToDBF.AddField(i.TABN, 7);
      exportToDBF.AddField(i.ZVET, 10);
      exportToDBF.AddField(i.SORT, 10);
      exportToDBF.AddField(i.PPVK, 1);
      exportToDBF.AddField(i.DATV);
      exportToDBF.AddField(i.DKOR);
      exportToDBF.AddField(i.TABKOR, 7);
      exportToDBF.AddField(i.OKEI, 5);
      exportToDBF.AddField(l_sysdate);
      exportToDBF.AddField(l_time, 8);
      exportToDBF.AddField(i.P_NAIM, 254);
      exportToDBF.AddField(k, 6);
      exportToDBF.AddField(i.PRIZN, 1);

    END LOOP;

    exportToDBF.DataEndWrite();

  END;

  -- экспорт
  PROCEDURE Export
  IS
    l_file VARCHAR2(50);
    l_isExists BOOLEAN;
    l_file_length NUMBER;
    l_block_size BINARY_INTEGER;
  BEGIN
    -- назначение имени файла
    l_file := 'm' || To_Char(SYSDATE, 'YYMMDD') || '.dbf';

    -- проверка на существование файла
    Utl_File.FGetAttr(
      pkg_dir,
      l_file,
      l_isExists,
      l_file_length,
      l_block_size
      );

    -- инициализация
    exportToDBF.InizializeDBF(
      p_dir => pkg_dir,
      p_file => l_file,
      p_str_mode => exportToDBF.STR_MODE_DEFAULT
      );

    -- если необходимо создать новый файл, то...
    IF NOT l_isExists THEN
      -- задание полей
      exportToDBF.InizializeColumns();
      exportToDBF.AddColumn('MAT', 'N', 7, 0);
      exportToDBF.AddColumn('SKL', 'N', 3, 0);
      exportToDBF.AddColumn('POZ1', 'N', 4, 0);
      exportToDBF.AddColumn('POZ2', 'N', 4, 0);
      exportToDBF.AddColumn('EIO', 'N', 3, 0);
      exportToDBF.AddColumn('GRU', 'N', 7, 0);
      exportToDBF.AddColumn('NAIM', 'C', 20, 0);
      exportToDBF.AddColumn('MARK', 'C', 20, 0);
      exportToDBF.AddColumn('DIAM', 'C', 2, 0);
      exportToDBF.AddColumn('DM', 'N', 10, 3);
      exportToDBF.AddColumn('CLT', 'N', 1, 0);
      exportToDBF.AddColumn('TOL', 'N', 10, 3);
      exportToDBF.AddColumn('CHIR', 'N', 10, 3);
      exportToDBF.AddColumn('DL', 'N', 10, 3);
      exportToDBF.AddColumn('GOST', 'C', 30, 0);
      exportToDBF.AddColumn('SORM', 'C', 25, 0);
      exportToDBF.AddColumn('KOEF', 'N', 4, 2);
      exportToDBF.AddColumn('EID1', 'N', 3, 0);
      exportToDBF.AddColumn('UDN1', 'N', 8, 3);
      exportToDBF.AddColumn('EID2', 'N', 3, 0);
      exportToDBF.AddColumn('UDN2', 'N', 8, 3);
      exportToDBF.AddColumn('VED', 'N', 2, 0);
      exportToDBF.AddColumn('TABN', 'N', 7, 0);
      exportToDBF.AddColumn('ZVET', 'C', 10, 0);
      exportToDBF.AddColumn('SORT', 'C', 10, 0);
      exportToDBF.AddColumn('PPVK', 'N', 1, 0);
      exportToDBF.AddColumn('DATV', 'D', 8, 0);
      exportToDBF.AddColumn('DKOR', 'D', 8, 0);
      exportToDBF.AddColumn('TABKOR', 'N', 7, 0);
      exportToDBF.AddColumn('OKEI', 'N', 5, 0);
      exportToDBF.AddColumn('DVIGR', 'D', 8, 0);
      exportToDBF.AddColumn('TVIGR', 'C', 8, 0);
      exportToDBF.AddColumn('P_NAIM', 'C', 254, 0);
      exportToDBF.AddColumn('NOMSTR', 'N', 6, 0);
      exportToDBF.AddColumn('PRIZN', 'N', 1, 0);

      -- установка данных
      BuildData();

      -- экспорт
      exportToDBF.Export();

    ELSE
      BuildData( exportToDBF.CountRecords());

      -- иначе, данные добавляются в конец файла
      exportToDBF.AppendData();

    END IF;

  END;

  PROCEDURE SelectMatRow(
    p_status NUMBER,
    p_priznak NUMBER,
    p_soCode NUMBER,
    p_plCode materials.plCode%TYPE,
    p_meas_1 NUMBER,
    p_meas_2 NUMBER,
    p_meas_3 NUMBER,
    p_create_date DATE,
    p_modify_date DATE,
    p_create_user NUMBER,
    p_modify_user NUMBER
  )
  IS
    l_isExists BOOLEAN;
    l_file_length NUMBER;
    l_block_size BINARY_INTEGER;

    TYPE dictAttrs IS TABLE OF NUMBER INDEX BY obj_attributes.name%TYPE;
    attrs dictAttrs;

    l_query VARCHAR2(1000);
    l_rec sepo_export_materials%ROWTYPE;

    l_tabExists NUMBER;
    l_fileName VARCHAR2(100);

    -- диаметр
    l_dm NUMBER;
    -- сечение
    l_cut VARCHAR2(255);
    -- толщина
    l_tol NUMBER;
    -- количество жил
    l_cnt_zhil NUMBER;
  BEGIN
    -- запись для заполнения данных
    l_rec := NULL;

    -- статус
    l_rec.STATUS := p_status;
    -- признак
    l_rec.PRIZN := p_priznak;
    -- дата создания
    l_rec.DATV := p_create_date;
    -- дата изменения
    IF p_priznak > 0 THEN
      l_rec.DKOR := p_modify_date;
    END IF;

    -- табельный номер позьзователя, создавшего материал
    l_rec.TABN := NULL;

    SELECT
      Count(*)
    INTO
      l_tabExists
    FROM
      user_list ul,
      labouring_list people
    WHERE
        ul.code = p_create_user
      AND
        ul.labouring = people.code;

    IF l_tabExists > 0 THEN
      SELECT
        people.id
      INTO
        l_rec.TABN
      FROM
        user_list ul,
        labouring_list people
      WHERE
          ul.code = p_create_user
        AND
          ul.labouring = people.code;

    END IF;

    -- табельный номер позьзователя, редактирующего материал
    l_rec.TABKOR := NULL;

    IF p_priznak > 0 THEN
      SELECT
        Count(*)
      INTO
        l_tabExists
      FROM
        user_list ul,
        labouring_list people
      WHERE
          ul.code = p_modify_user
        AND
          ul.labouring = people.code;

      IF l_tabExists > 0 THEN
        SELECT
          people.id
        INTO
          l_rec.TABKOR
        FROM
          user_list ul,
          labouring_list people
        WHERE
            ul.code = p_modify_user
          AND
            ul.labouring = people.code;

      END IF;

    END IF;

    -- заводской код
    l_rec.MAT := p_plCode;

    -- получить список атрибутов на материал
    FOR i IN (
      SELECT
        code,
        shortName
      FROM
        obj_attributes
      WHERE
          objType = 1000001

    ) LOOP
      attrs(i.shortName) := i.code;

    END LOOP;

    /* выборка значений из атрибутов */
    l_query :=
      'SELECT ' ||
        'A_' || attrs('SKL') || ' as SKL,' ||
        'A_' || attrs('CEN') || ' as CEN,' ||
        'A_' || attrs('POZ1') || ' as POZ1,' ||
        'A_' || attrs('POZ2') || ' as POZ2,' ||
        'A_' || attrs('GRU') || ' as GRU,' ||
        'A_' || attrs('NAIM') || ' as NAIM,' ||
        'A_' || attrs('MARK') || ' as MARK,' ||
        'A_' || attrs('DIAM') || ' as DIAM,' ||
        'A_' || attrs('D') || ' as DM,' ||
        'A_' || attrs('Сечение_') || ' as CUT,' ||
        'A_' || attrs('CLT') || ' as CLT,' ||
        'A_' || attrs('Толщина') || ' as TOL,' ||
        'A_' || attrs('Количество_жил') || ' as ZGIL,' ||
        'A_' || attrs('W') || ' as CHIR,' ||
        'A_' || attrs('L') || ' as DL,' ||
        'A_' || attrs('GOST') || ' as GOST,' ||
        'A_' || attrs('SORM') || ' as SORM,' ||
        'A_' || attrs('KOEF') || ' as KOEF,' ||
        'A_' || attrs('UDN1') || ' as UDN1,' ||
        'A_' || attrs('UDN2') || ' as UDN2,' ||
        'A_' || attrs('VED') || ' as VED,' ||
        'A_' || attrs('ZVET') || ' as ZVET,' ||
        'A_' || attrs('SORT') || ' as SORT,' ||
        'A_' || attrs('PPVK') || ' as PPVK,' ||
        'A_' || attrs('VPR') || ' as VPR,' ||
        'A_' || attrs('OKEI') || ' as OKEI,' ||
        'A_' || attrs('P_NAIM') || ' as P_NAIM ' ||
      'FROM ' ||
        'obj_attr_values_1000001 attr_1000001 ' ||
      'WHERE ' ||
          'attr_1000001.soCode = :1';

    EXECUTE IMMEDIATE l_query
    INTO
      l_rec.SKL,
      l_rec.CEN,
      l_rec.POZ1,
      l_rec.POZ2,
      l_rec.GRU,
      l_rec.NAIM,
      l_rec.MARK,
      l_rec.DIAM,
      l_dm,
      l_cut,
      l_rec.CLT,
      l_tol,
      l_cnt_zhil,
      l_rec.CHIR,
      l_rec.DL,
      l_rec.GOST,
      l_rec.SORM,
      l_rec.KOEF,
      l_rec.UDN1,
      l_rec.UDN2,
      l_rec.VED,
      l_rec.ZVET,
      l_rec.SORT,
      l_rec.PPVK,
      l_rec.VPR,
      l_rec.OKEI,
      l_rec.P_NAIM
    USING
      p_soCode;

    IF Nvl(l_dm, 0) != 0 AND Nvl(l_cnt_zhil, 0) != 0 THEN
      RAISE EXP_MAT_NOT_CORRECT_DM_EXCEPTION;
    END IF;

    IF Nvl(l_tol, 0) != 0 AND Nvl(To_Number(l_cut), 0) != 0 THEN
      RAISE EXP_MAT_NOT_CORRECT_TOL_EXCEPTION;
    END IF;

    IF Nvl(l_dm, 0) != 0 THEN
      l_rec.DM := l_dm;
    ELSE
      l_rec.DM := l_cnt_zhil;
    END IF;

    IF Nvl(l_tol, 0) != 0 THEN
      l_rec.TOL := l_tol;
    ELSE
      l_rec.TOL := To_Number(l_cut);
    END IF;

    -- единицы измерения
    IF p_meas_1 IS NOT NULL THEN
      SELECT
        meas_1.code_bmn
      INTO
        l_rec.EIO
      FROM
        measures meas_1
      WHERE
          meas_1.code = p_meas_1;

    END IF;

    IF p_meas_2 IS NOT NULL THEN
      SELECT
        meas_2.code_bmn
      INTO
        l_rec.EID1
      FROM
        measures meas_2
      WHERE
          meas_2.code = p_meas_2;

    END IF;

    IF p_meas_3 IS NOT NULL THEN
      SELECT
        meas_3.code_bmn
      INTO
        l_rec.EID2
      FROM
        measures meas_3
      WHERE
          meas_3.code = p_meas_3;

    END IF;

    /* добавление полученных данных */
    INSERT INTO sepo_export_materials
    VALUES
    l_rec;

--  EXCEPTION
--    WHEN OTHERS THEN RAISE;

  END;

  PROCEDURE SelectTmcRow(
    p_status NUMBER,
    p_priznak NUMBER,
    p_soCode NUMBER,
    p_plCode stock_other.Sign%TYPE,
    p_meas_1 NUMBER,
    p_create_date DATE,
    p_modify_date DATE,
    p_create_user NUMBER,
    p_modify_user NUMBER
  )
  IS
    l_tabExists NUMBER;
    l_isExists BOOLEAN;
    l_file_length NUMBER;
    l_block_size BINARY_INTEGER;

    TYPE dictAttrs IS TABLE OF NUMBER INDEX BY obj_attributes.name%TYPE;
    attrs dictAttrs;

    l_query VARCHAR2(1000);
    l_rec sepo_export_materials%ROWTYPE;

    l_fileName VARCHAR2(100);
  BEGIN
    l_rec := NULL;

    l_rec.STATUS := p_status;
    l_rec.PRIZN := p_priznak;

    -- заводской код
    l_rec.MAT := p_plCode;

    -- даты
    l_rec.DATV := p_create_date;
    IF p_priznak > 0 THEN
      l_rec.DKOR := p_modify_date;
    END IF;

    -- табельные номера
    l_rec.TABN := NULL;

    SELECT
      Count(*)
    INTO
      l_tabExists
    FROM
      user_list ul,
      labouring_list people
    WHERE
        ul.code = p_create_user
      AND
        ul.labouring = people.code;

    IF l_tabExists > 0 THEN
      SELECT
        people.id
      INTO
        l_rec.TABN
      FROM
        user_list ul,
        labouring_list people
      WHERE
          ul.code = p_create_user
        AND
          ul.labouring = people.code;

    END IF;

    -- табельный номер позьзователя, редактирующего материал
    l_rec.TABKOR := NULL;

    IF p_priznak > 0 THEN
      SELECT
        Count(*)
      INTO
        l_tabExists
      FROM
        user_list ul,
        labouring_list people
      WHERE
          ul.code = p_modify_user
        AND
          ul.labouring = people.code;

      IF l_tabExists > 0 THEN
        SELECT
          people.id
        INTO
          l_rec.TABKOR
        FROM
          user_list ul,
          labouring_list people
        WHERE
            ul.code = p_modify_user
          AND
            ul.labouring = people.code;

      END IF;

    END IF;

    /* получить список атрибутов на материал */
    FOR i IN (
      SELECT
        code,
        shortName
      FROM
        obj_attributes
      WHERE
          objType = 1000045

    ) LOOP
      attrs(i.shortName) := i.code;

    END LOOP;


    /* выборка значений из атрибутов */
    l_query :=
      'SELECT ' ||
        'A_' || attrs('SKL') || ' as SKL,' ||
        'A_' || attrs('CEN') || ' as CEN,' ||
        'A_' || attrs('POZ1') || ' as POZ1,' ||
        'A_' || attrs('POZ2') || ' as POZ2,' ||
        'A_' || attrs('GRU') || ' as GRU,' ||
        'A_' || attrs('NAIM') || ' as NAIM,' ||
        'A_' || attrs('MARK') || ' as MARK,' ||
        'A_' || attrs('DIAM') || ' as DIAM,' ||
        'A_' || attrs('DM') || ' as DM,' ||
        'A_' || attrs('CLT') || ' as CLT,' ||
        'A_' || attrs('TOL') || ' as TOL,' ||
        'A_' || attrs('CHIR') || ' as CHIR,' ||
        'A_' || attrs('DL') || ' as DL,' ||
        'A_' || attrs('GOST') || ' as GOST,' ||
        'A_' || attrs('SORM') || ' as SORM,' ||
        'A_' || attrs('KOEF') || ' as KOEF,' ||
        'A_' || attrs('EID1') || ' as EID1,' ||
        'A_' || attrs('UDN1') || ' as UDN1,' ||
        'A_' || attrs('EID2') || ' as EID2,' ||
        'A_' || attrs('UDN2') || ' as UDN2,' ||
        'A_' || attrs('VED') || ' as VED,' ||
        'A_' || attrs('ZVET') || ' as ZVET,' ||
        'A_' || attrs('SORT') || ' as SORT,' ||
        'A_' || attrs('PPVK') || ' as PPVK,' ||
        'A_' || attrs('VPR') || ' as VPR,' ||
        'A_' || attrs('OKEI') || ' as OKEI,' ||
        'A_' || attrs('P_NAIM') || ' as P_NAIM ' ||
      'FROM ' ||
        'obj_attr_values_1000045 attr_1000045 ' ||
      'WHERE ' ||
          'attr_1000045.soCode = :1';

    EXECUTE IMMEDIATE l_query
    INTO
      l_rec.SKL,
      l_rec.CEN,
      l_rec.POZ1,
      l_rec.POZ2,
      l_rec.GRU,
      l_rec.NAIM,
      l_rec.MARK,
      l_rec.DIAM,
      l_rec.DM,
      l_rec.CLT,
      l_rec.TOL,
      l_rec.CHIR,
      l_rec.DL,
      l_rec.GOST,
      l_rec.SORM,
      l_rec.KOEF,
      l_rec.EID1,
      l_rec.UDN1,
      l_rec.EID2,
      l_rec.UDN2,
      l_rec.VED,
      l_rec.ZVET,
      l_rec.SORT,
      l_rec.PPVK,
      l_rec.VPR,
      l_rec.OKEI,
      l_rec.P_NAIM
    USING
      p_soCode;

    -- единицы измерения
    IF p_meas_1 IS NOT NULL THEN
      SELECT
        meas_1.code_bmn
      INTO
        l_rec.EIO
      FROM
        measures meas_1
      WHERE
          meas_1.code = p_meas_1;

    END IF;

    /* добавление полученных данных */
    INSERT INTO sepo_export_materials
    VALUES
    l_rec;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE;

  END;

END;
/

