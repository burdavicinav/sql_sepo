PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_export_kompl
CREATE OR REPLACE PACKAGE pkg_sepo_export_kompl
IS
  pkg_dir CONSTANT VARCHAR2(100) := 'DBF_DIR';

  PROCEDURE Clear;

  -- экспорт
  -- p_dir: директория
  -- p_file: имя файла
  PROCEDURE Export;

  -- формирует строку данных для дальнейшего экспорта
  PROCEDURE SelectRow(
    p_bocode NUMBER,
    p_modify_date DATE,
    p_modify_user NUMBER,
    p_status NUMBER,
    p_priznak NUMBER
  );

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_export_kompl
CREATE OR REPLACE PACKAGE BODY pkg_sepo_export_kompl
IS
  TYPE DictAttrs IS TABLE OF NUMBER INDEX BY obj_attributes.name%TYPE;
  pkg_attrs DictAttrs;

  PROCEDURE Clear
  IS
  BEGIN
    DELETE FROM sepo_export_kompl;
  END;

  PROCEDURE BuildData(p_number_str NUMBER := 0)
  IS
    l_sysDate DATE DEFAULT SYSDATE;
    l_time VARCHAR2(8);

    k NUMBER;
  BEGIN
    l_time := To_Char(SYSDATE, 'HH24:MI:SS');

    exportToDBF.DataBeginWrite();
    k := p_number_str;

    FOR i IN (SELECT data.* FROM sepo_export_kompl data) LOOP
      k := k + 1;

      exportToDBF.NewRecord();
      exportToDBF.AddField(i.PKI, 9);
      exportToDBF.AddField(i.SKL, 3);
      exportToDBF.AddField(i.GR, 3);
      exportToDBF.AddField(i.EDI, 3);
      exportToDBF.AddField(Upper(i.NPKI), 35);
      exportToDBF.AddField(i.VID, 40);
      exportToDBF.AddField(i.Chr, 20);
      exportToDBF.AddField(i.NOMZ, 7);
      exportToDBF.AddField(i.EDN, 7);
      exportToDBF.AddField(i.DOP, 9);
      exportToDBF.AddField(i.VISP, 7);
      exportToDBF.AddField(i.VPR, 6);
      exportToDBF.AddField(i.IND, 4);
      exportToDBF.AddField(i.DATA);
      exportToDBF.AddField(i.GOST, 25);
      exportToDBF.AddField(i.GOST1, 25);
      exportToDBF.AddField(i.OKP, 11);
      exportToDBF.AddField(i.TAB, 7);
      exportToDBF.AddField(i.OKEI, 5);
      exportToDBF.AddField(i.DATAK);
      exportToDBF.AddField(i.TABK, 7);
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
    l_file := 'k' || To_Char(SYSDATE, 'YYMMDD') || '.dbf';

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
      exportToDBF.AddColumn('PKI', 'N', 9, 0);
      exportToDBF.AddColumn('SKL', 'N', 3, 0);
      exportToDBF.AddColumn('GR', 'N', 3, 0);
      exportToDBF.AddColumn('EDI', 'N', 3, 0);
      exportToDBF.AddColumn('NPKI', 'C', 35, 0);
      exportToDBF.AddColumn('VID', 'C', 40, 0);
      exportToDBF.AddColumn('CHR', 'C', 20, 0);
      exportToDBF.AddColumn('NOMZ', 'C', 7, 0);
      exportToDBF.AddColumn('EDN', 'C', 7, 0);
      exportToDBF.AddColumn('DOP', 'C', 9, 0);
      exportToDBF.AddColumn('VISP', 'C', 7, 0);
      exportToDBF.AddColumn('VPR', 'C', 6, 0);
      exportToDBF.AddColumn('IND', 'C', 4, 0);
      exportToDBF.AddColumn('DATA', 'D', 8, 0);
      exportToDBF.AddColumn('GOST', 'C', 25, 0);
      exportToDBF.AddColumn('GOST1', 'C', 25, 0);
      exportToDBF.AddColumn('OKP', 'N', 11, 0);
      exportToDBF.AddColumn('TAB', 'N', 7, 0);
      exportToDBF.AddColumn('OKEI', 'N', 5, 0);
      exportToDBF.AddColumn('DATAK', 'D', 8, 0);
      exportToDBF.AddColumn('TABK', 'N', 7, 0);
      exportToDBF.AddColumn('DVIGR', 'D', 8, 0);
      exportToDBF.AddColumn('TVIGR', 'C', 8, 0);
      exportToDBF.AddColumn('P_NAIM', 'C', 254, 0);
      exportToDBF.AddColumn('NOMSTR', 'N', 6, 0);
      exportToDBF.AddColumn('PRIZN', 'N', 1, 0);

      BuildData();

      -- экспорт
      exportToDBF.Export();

    ELSE
      -- установка данных
      BuildData( exportToDBF.CountRecords());

      -- иначе, данные добавляются в конец файла
      exportToDBF.AppendData();

    END IF;

  END;

  PROCEDURE GetAllAttrs
  IS

  BEGIN
    pkg_attrs.DELETE();

    FOR i IN (
      SELECT
        code,
        shortName
      FROM
        obj_attributes
      WHERE
          objType = 4

    ) LOOP
      pkg_attrs(i.shortName) := i.code;

    END LOOP;

  END;

  FUNCTION GetAttrCode(p_name obj_attributes.shortName%type)
  RETURN NUMBER
  IS

  BEGIN
    RETURN pkg_attrs(p_name);
  EXCEPTION
    WHEN No_Data_Found THEN
      Raise_Application_Error(-20101, 'Атрибут ' || p_name || ' не найден');

  END;

  PROCEDURE SelectRow(
    p_boCode NUMBER,
    p_modify_date DATE,
    p_modify_user NUMBER,
    p_status NUMBER,
    p_priznak NUMBER
  )
  IS
    l_count NUMBER;
    l_currentRevision business_objects%ROWTYPE;
    l_startRevision business_objects%ROWTYPE;

    l_query VARCHAR2(1000);
    l_rec sepo_export_kompl%ROWTYPE;
    l_dop_meas_code NUMBER;
    l_dop_meas measures.shortName%TYPE;
  BEGIN
    -- запись для заполнения данных
    l_rec := NULL;

    l_rec.STATUS := p_status;
    l_rec.PRIZN := p_priznak;

    -- данные текущей ревизии
    SELECT
      *
    INTO
      l_currentRevision
    FROM
      business_objects bo
    WHERE
        bo.code = p_boCode;

    -- стартовая ревизия
    SELECT
      *
    INTO
      l_startRevision
    FROM
      business_objects bo
    WHERE
        bo.prodCode = l_currentRevision.prodCode
      AND
        bo.revision = (
          SELECT
            Min(bo_.revision)
          FROM
            business_objects bo_
          WHERE
              bo_.prodCode = bo.prodCode
              );

    -- обозначение
    l_rec.PKI := l_startRevision.name;

    -- даты
    l_rec.DATA := l_startRevision.create_date;
    IF p_priznak > 0 THEN
      l_rec.DATAK := p_modify_date;
    END IF;

    -- табельные номера
    l_rec.TAB := NULL;

    SELECT
      Count(*)
    INTO
      l_count
    FROM
      user_list ul,
      labouring_list l
    WHERE
        ul.code = l_startRevision.create_user
      AND
        l.code = ul.labouring;

    IF l_count > 0 THEN
      SELECT
        l.id
      INTO
        l_rec.TAB
      FROM
        user_list ul,
        labouring_list l
      WHERE
          ul.code = l_startRevision.create_user
        AND
          l.code = ul.labouring;

    END IF;

    -- табельные номера
    l_rec.TABK := NULL;

    IF p_priznak > 0 THEN
      SELECT
        Count(*)
      INTO
        l_count
      FROM
        user_list ul,
        labouring_list l
      WHERE
          ul.code = p_modify_user
        AND
          l.code = ul.labouring;

      IF l_count > 0 THEN
        SELECT
          l.id
        INTO
          l_rec.TABK
        FROM
          user_list ul,
          labouring_list l
        WHERE
            ul.code = p_modify_user
          AND
            l.code = ul.labouring;

      END IF;

    END IF;

    -- единица измерения
    SELECT
      u.code_bmn,
      ko.name
    INTO
      l_rec.EDI,
      l_rec.P_NAIM
    FROM
      konstrobj ko,
      measures u
    WHERE
        ko.unvCode = l_currentRevision.docCode
      AND
        u.code = ko.measCode;

    /* получить список атрибутов на материал */
    GetAllAttrs();

    /* выборка значений из атрибутов */
    l_query :=
      'SELECT ' ||
        'A_' || GetAttrCode('SKL') || ' as SKL,' ||
        'A_' || GetAttrCode('GR') || ' as GR,' ||
        'A_' || GetAttrCode('NPKI') || ' as NPKI,' ||
        'A_' || GetAttrCode('VID') || ' as VID,' ||
        'A_' || GetAttrCode('CHR') || ' as CHR,' ||
        'A_' || GetAttrCode('NOMZ') || ' as NOMZ,' ||
        'A_' || GetAttrCode('EDN') || ' as EDN,' ||
        'A_' || GetAttrCode('DOP') || ' as DOP,' ||
        'M_' || GetAttrCode('DOP') || ' as M_DOP,' ||
        'A_' || GetAttrCode('VISP') || ' as VISP,' ||
        'A_' || GetAttrCode('VPR') || ' as VPR,' ||
        'A_' || GetAttrCode('IND') || ' as IND,' ||
        'A_' || GetAttrCode('GOST') || ' as GOST,' ||
        'A_' || GetAttrCode('GOST1') || ' as GOST1,' ||
        'A_' || GetAttrCode('OKP') || ' as OKP,' ||
        'A_' || GetAttrCode('OKEI') || ' as OKEI ' ||
--        'A_' || GetAttrCode('P_NAIM') || ' as P_NAIM ' ||
      'FROM ' ||
        'obj_attr_values_4 attr_4 ' ||
      'WHERE ' ||
          'attr_4.soCode = :1';

--    Dbms_Output.put_line(l_query);
    EXECUTE IMMEDIATE l_query
    INTO
      l_rec.SKL,
      l_rec.GR,
      l_rec.NPKI,
      l_rec.VID,
      l_rec.CHR,
      l_rec.NOMZ,
      l_rec.EDN,
      l_rec.DOP,
      l_dop_meas_code,
      l_rec.VISP,
      l_rec.VPR,
      l_rec.IND,
      l_rec.GOST,
      l_rec.GOST1,
      l_rec.OKP,
      l_rec.OKEI
--      l_rec.P_NAIM
    USING
      p_bocode;

    -- если значения и атрибута DOP и его единицы измерения указаны...
    IF l_rec.DOP IS NOT NULL AND l_dop_meas_code IS NOT NULL THEN
      SELECT shortName INTO l_dop_meas FROM measures
      WHERE code = l_dop_meas_code;

      l_rec.DOP := l_rec.DOP || l_dop_meas;
    END IF;
    /* добавление полученных данных */
    INSERT INTO sepo_export_kompl
    VALUES
    l_rec;

  END;

END;
/