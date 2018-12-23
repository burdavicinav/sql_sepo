CREATE OR REPLACE PACKAGE pkg_sepo_import_maters
IS
  /* строка импорта */
  pkg_importRowMaterialData sepo_maters%ROWTYPE;

  MAT_STATE_UNCONFIRMED CONSTANT NUMBER := 0;
  MAT_STATE_CONFIRMED CONSTANT NUMBER := 1;
  MAT_STATE_ANNUL CONSTANT NUMBER := 2;

  /*
  p_user_name - логин
  p_owner_name - владелец
  p_matState - статус материала
  p_notice - примечание
  */
  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_matState NUMBER,
    p_notice stockObj.notice%TYPE DEFAULT NULL,
    p_classifyName classify.clcode%TYPE DEFAULT NULL
  );
  /* сброс настроек */
  PROCEDURE Clear;

  /* создание материала */
  PROCEDURE CreateMaterial;
  /* создание ТМЦ */
  PROCEDURE CreateOtherItem;

  -- начало истории материала
  PROCEDURE WriteMatHistory;

  -- начала истории ТМЦ
  PROCEDURE WriteOIHistory;

  -- создание классификатора материалов
  PROCEDURE CreateMatClassify( p_name VARCHAR2 );

  -- создание классификатора ТМЦ
  PROCEDURE CreateTMCClassify( p_name VARCHAR2 );

  -- загрузка сплавов
  PROCEDURE LoadMixture;
END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_maters
CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_maters
IS
  /* константы */
  pkg_materialTypeCode CONSTANT NUMBER := 1000001;
  pkg_stockItemTypeCode CONSTANT NUMBER := 1000045;
  pkg_markTypeCode CONSTANT NUMBER := 1000010;

  -- XML схема на метариал
  pkg_matHistory CONSTANT VARCHAR2(200) :=
    '<OmegaProduction>' || Chr(10) ||
	  '  <Материал>' || Chr(10) ||
	  '	  <CO>' || Chr(10) ||
	  '	  </CO>' || Chr(10) ||
	  '  </Материал>' || Chr(10) ||
    '</OmegaProduction>';

  /* определение стандартных типов КИС "Омега" */
  STRING_ CONSTANT NUMBER := pkg_sepo_attr_operations.ATTR_TYPE_STRING;
  DOUBLE_ CONSTANT NUMBER := pkg_sepo_attr_operations.ATTR_TYPE_DOUBLE;
  INT_ CONSTANT NUMBER := pkg_sepo_attr_operations.ATTR_TYPE_INT;
  DATE_ CONSTANT NUMBER := pkg_sepo_attr_operations.ATTR_TYPE_DATE;

  /* настройки */
  TYPE ImportSettings IS RECORD (
    userCode NUMBER,
    userName user_list.loginName%TYPE,
    ownerCode NUMBER,
    ownerName owner_name.name%TYPE,
    matState NUMBER,
    notice stockObj.notice%TYPE,
    classifyName classify.clCode%TYPE,
    matClassifyCode NUMBER
  );

  /* объект настроек */
  pkg_settings ImportSettings;

  PROCEDURE Clear
  IS

  BEGIN
    pkg_settings := NULL;

  END;

  /* инициализация настроек */
  /* в частности получение кодов имени пользователя
  и владельца */
  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_matState NUMBER,
    p_notice stockObj.notice%TYPE DEFAULT NULL,
    p_classifyName classify.clcode%TYPE DEFAULT NULL
  )
  IS
    l_count NUMBER;

    l_user_not_exists EXCEPTION;
    l_owner_not_exists EXCEPTION;
    l_classifyNotExistsException EXCEPTION;

  BEGIN
    Clear();

    SELECT
      Count(*)
    INTO
      l_count
    FROM
      user_list
    WHERE
        loginName = p_userName;

    IF l_count = 0 THEN RAISE l_user_not_exists; END IF;

    SELECT
      code
    INTO
      pkg_settings.userCode
    FROM
      user_list
    WHERE
        loginName = p_userName;

    pkg_settings.userName := p_userName;

    SELECT
      Count(*)
    INTO
      l_count
    FROM
      owner_name
    WHERE
        name = p_ownerName;

    IF l_count = 0 THEN RAISE l_owner_not_exists; END IF;

    SELECT
      owner
    INTO
      pkg_settings.ownerCode
    FROM
      owner_name
    WHERE
        name = p_ownerName;

    IF p_classifyName IS NOT NULL THEN
      SELECT
        Count(*)
      INTO
        l_count
      FROM
        classify
      WHERE
          clType = 12
        AND
          clCode = p_classifyName;

      IF l_count != 1 THEN RAISE l_classifyNotExistsException; END IF;

      SELECT
        code
      INTO
        pkg_settings.matClassifyCode
      FROM
        classify
      WHERE
          clType = 12
        AND
          clCode = p_classifyName;

    END IF;

    pkg_settings.classifyName := p_classifyName;
    pkg_settings.ownerName := p_ownerName;
    pkg_settings.matState := p_matState;
    pkg_settings.notice := p_notice;

  EXCEPTION
    WHEN l_user_not_exists THEN
      Raise_Application_Error( -20103, 'Ошибка! Пользователя ' || p_userName || ' не существует' );
    WHEN l_owner_not_exists THEN
      Raise_Application_Error( -20103, 'Ошибка! Владельца ' || p_ownerName || ' не существует' );
    WHEN l_classifyNotExistsException THEN
      Raise_Application_Error( -20103, 'Ошибка! Классификатор не существует или задан неоднозначно');
    WHEN OTHERS THEN
      RAISE;

  END;

  procedure p_sepo_import_maters_log ( id NUMBER, message VARCHAR2 )
  AS
    pragma autonomous_transaction;
    begin
    INSERT INTO sepo_import_maters_log
    VALUES
    ( id, message );

    COMMIT;

  end;

  /* заполнение справочник марок материала ( не используется) */
  PROCEDURE CreateMaterialMark ( p_code OUT NUMBER )
  IS
    l_businessObjectCode NUMBER;
    l_markCode NUMBER;

  BEGIN
    SELECT sq_business_objects_code.NEXTVAL INTO l_businessObjectCode FROM dual;

    INSERT INTO omp_objects
    (code,objType,scheme,num)
    VALUES
    (l_businessObjectCode, pkg_markTypeCode, NULL, so.GetNextSoNum);

    /*атрибуты*/

    SELECT sq_material_marks.NEXTVAL INTO p_code FROM dual;

    INSERT INTO material_marks
    (code,soCode,class_code,name,note,recUser,recDate,modifyUser,modifyDate,gost,
      gost2,gost3,gost4,gost5,state,owner,machinability_group_iso,brinell_hardness,
        cutting_force,machinability_subGroup_cmc,addName)
    VALUES
    (p_code,l_businessObjectCode,NULL,pkg_importRowMaterialData.MARK,NULL,
      pkg_settings.userCode,SYSDATE,pkg_settings.userCode,SYSDATE,NULL,NULL,NULL,NULL,NULL,0,pkg_settings.ownerCode,
        NULL,NULL,NULL,NULL,pkg_importRowMaterialData.MARK);

  END;

  /* создание ГОСТа. Заполняется справочник ГОСТов. Возвращает код из БД.*/
  PROCEDURE CreateGost( p_gostName maretial_gosts.name%TYPE, p_code OUT NUMBER )
  IS

  BEGIN
    SELECT sq_maretial_gosts.NEXTVAL INTO p_code FROM dual;

    INSERT INTO maretial_gosts
    ( code, name, recUser, recDate, modifyUser, modifyDate )
    VALUES
    ( p_code, p_gostName, pkg_settings.userCode, SYSDATE, pkg_settings.userCode, SYSDATE );

  END;

  /* по заддоному ГОСТу возвращает его код в БД.
  Если в БД ГОСТ отсутствует, то он создается */
  FUNCTION GetGost( p_gostName maretial_gosts.name%type)
  RETURN NUMBER
  IS
    l_gostCode NUMBER;

  BEGIN
    IF p_gostName IS NULL THEN RETURN NULL; END IF;

    SELECT
      Count(code)
    INTO
      l_gostCode
    FROM
      maretial_gosts
    WHERE
        name = p_gostName;

    IF l_gostCode > 0 THEN
      SELECT
        Max(code)
      INTO
        l_gostCode
      FROM
        maretial_gosts
      WHERE
          name = p_gostName;

    ELSE
      CreateGost( p_gostName, l_gostCode );

    END IF;

    RETURN l_gostCode;


  END;

  FUNCTION GetOmegaUnit( p_unitBNMCode NUMBER )
  RETURN NUMBER
  IS
    l_omegaUnitCode NUMBER;
    l_count NUMBER;

    l_unit_not_exists EXCEPTION;

  BEGIN
    /* получение единиц измерения по коду БНМ */
    IF Nvl(p_unitBNMCode, 0) > 0 THEN

      SELECT
        Count(*)
      INTO
        l_count
      FROM
        measures ms
      WHERE
          ms.code_bmn = p_unitBNMCode;

      IF l_count = 0 THEN RAISE l_unit_not_exists; END IF;

      SELECT
        ms.code
      INTO
        l_omegaUnitCode
      FROM
        measures ms
      WHERE
          ms.code_bmn = p_unitBNMCode;

    ELSE
      l_omegaUnitCode := NULL;

    END IF;

    RETURN l_omegaUnitCode;


  EXCEPTION
    WHEN l_unit_not_exists THEN
--      Raise_Application_Error( -20104, 'Ошибка! По коду БНМ ' || p_unitBNMCode ||
--        ' не найдена единица измерения');

      RETURN -1;

    WHEN OTHERS THEN
      RAISE;

  END;

  /* процедура обновляет атрибуты материалы */
  PROCEDURE UpdateMaterialAttrs( p_objectCode NUMBER )
  IS
    /* переменная для перевода строки в дату по указанному формату */
    l_dateForParam DATE;

  BEGIN
    /* создание атрибутов */
    INSERT INTO obj_attr_values_1000001
    (soCode)
    VALUES
    ( p_objectCode );

    /* далее идет настройка атрибутов и установка значений */

    /* инициализация настроек */
    pkg_sepo_attr_operations.Init( pkg_materialTypeCode );

    /* для каждого атрибута вызывается функция привязки значений */
    /* принимает имя атрибута, тип и значение */
    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SKL',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.SKL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CEN',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CEN
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DATA, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DATA',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'POZ1',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.POZ1
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'POZ2',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.POZ2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'GRU',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.GRU
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'NAIM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.NAIM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'MARK',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.MARK
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DIAM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.DIAM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'D',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.DM,
      p_meas => 'Миллиметр'
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CLT',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.CLT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'Толщина',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.TOL,
      p_meas => 'Миллиметр'
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'W',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CHIR,
      p_meas => 'Миллиметр'
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'L',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.DL,
      p_meas => 'Миллиметр'
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'GOST',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.GOST
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SORM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.SORM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'KOEF',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.KOEF
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'UDN1',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.UDN1
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'UDN2',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.UDN2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'VED',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.VED
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRNOM',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PRNOM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENN',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENN
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SROKX',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.SROKX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRES',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRES
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESB',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESB
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TABN',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.TABN
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRIS',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PRIS
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SER',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.SER
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ZOL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.ZOL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ROD',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.ROD
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PAL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PAL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PLAT',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PLAT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PLAT_IR',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PLAT_IR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ZVET',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.ZVET
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SORT',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.SORT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENX',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESX',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PPVK',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PPVK
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'VPR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.VPR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'OBOZNGR',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.OBOZNGR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'KODGR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.KODGR
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DATV, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DATV',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DKOR, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DKOR',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TABKOR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.TABKOR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'OKEI',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.OKEI
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'IMP',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.IMP
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ORG',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.ORG
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'RUT',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.RUT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENGZ',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENGZ
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESGZ',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESGZ
    );

    /* ... и обновление заданных атрибутов */
    pkg_sepo_attr_operations.UpdateAttrs( p_objectCode );

    /* сброс настроек */
    pkg_sepo_attr_operations.Clear();

  END;

  FUNCTION IsExistsMaterial RETURN BOOLEAN
  IS
    l_count NUMBER;

  BEGIN
    SELECT
      Count(*)
    INTO
      l_count
    FROM
      materials
    WHERE
        plCode = To_Char(pkg_importRowMaterialData.MAT);

    RETURN ( l_count > 0 );

  END;

  FUNCTION CreateGroup(
    p_code groups_in_classify.grCode%TYPE,
    p_name groups_in_classify.grName%TYPE,
    p_clCode NUMBER,
    p_clType NUMBER
    )
  RETURN NUMBER
  IS
    l_soCode NUMBER;
    l_group NUMBER;
  BEGIN
    l_soCode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects
    (code, objType, num)
    VALUES
    (l_soCode, p_clType, so.GetNextSoNum() );

    EXECUTE IMMEDIATE
      'INSERT INTO obj_attr_values_' || p_clType ||
      '(soCode)' ||
      'VALUES' ||
      '(:1)'
    USING
      l_soCode;

    l_group := sq_groups_in_classify.NEXTVAL;

    INSERT INTO groups_in_classify
    (code, clCode, grCode, grName, soCode, owner)
    VALUES
    (l_group, p_clCode, p_code, p_name, l_soCode, pkg_settings.ownerCode);

    RETURN l_group;
  END;

  /* создание нового материала */
  PROCEDURE CreateMaterial
  IS
    l_businessObjectCode NUMBER;
    l_materialCode NUMBER;
    l_measCode_1 NUMBER;
    l_measCode_2 NUMBER;
    l_measCode_3 NUMBER;

    l_gostCode NUMBER;
    l_gostOnMarkCode NUMBER;
    l_gostOnMarkName maretial_gosts.name%TYPE;
    l_tuCode NUMBER;
    l_tuName maretial_gosts.name%TYPE;

    l_sormCode NUMBER;
    l_stockObjCode NUMBER;
    l_materialStateCode NUMBER;

    l_description stockObj.description%TYPE;
    l_sign stockObj.Sign%TYPE;
--    CURSOR SoInfoRecordCursor ( rec_id in integer ) is
--      SELECT T.*, count(1) over() as FOUND FROM T_SO_INFO_RECORD T WHERE id = rec_id;
--    l_rec SoInfoRecordCursor%ROWTYPE;
--    l_rec_id INTEGER;

    l_datv DATE;
    l_dkor DATE;

    l_groupCode NUMBER;

    l_existsMaterialException EXCEPTION;
    l_unit1_not_exists EXCEPTION;
    l_unit2_not_exists EXCEPTION;
    l_unit3_not_exists EXCEPTION;
    l_unsupported_format_date EXCEPTION;

  BEGIN
    IF IsExistsMaterial THEN
      RAISE l_existsMaterialException;

    END IF;

    /* получение единиц измерения */
    l_measCode_1 := GetOmegaUnit(pkg_importRowMaterialData.EIO);
    l_measCode_2 := GetOmegaUnit(pkg_importRowMaterialData.EID1);
    l_measCode_3 := GetOmegaUnit(pkg_importRowMaterialData.EID2);

    IF l_measCode_1 = -1 THEN
      RAISE l_unit1_not_exists;

    END IF;

    IF l_measCode_2 = -1 THEN
      RAISE l_unit2_not_exists;

    END IF;

    IF l_measCode_3 = -1 THEN
      RAISE l_unit3_not_exists;

    END IF;

    /* проверка формата дат */
    /* должен быть формат DD.MM.YYYY */
    IF pkg_importRowMaterialData.DATV IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DATV,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;

    IF pkg_importRowMaterialData.DKOR IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DKOR,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;

    IF pkg_importRowMaterialData.DATA IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DATA,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;

    -- приведение дат к необходимому виду
    l_datv := To_Date(
      coalesce( pkg_importRowMaterialData.DATV, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    l_dkor := To_Date(
      coalesce( pkg_importRowMaterialData.DKOR, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    SELECT sq_business_objects_code.NEXTVAL INTO l_businessObjectCode FROM dual;

    INSERT INTO omp_objects
    (code,objType,scheme,num)
    VALUES
    (l_businessObjectCode, pkg_materialTypeCode, NULL, so.GetNextSoNum);

     /* заполнение атрибутов */
    UpdateMaterialAttrs( l_businessObjectCode );

    /* ГОСТы */
    l_gostCode := GetGost( pkg_importRowMaterialData.GOST );
    l_sormCode := GetGost( pkg_importRowMaterialData.SORM );

    l_gostOnMarkCode := NULL;
    l_gostOnMarkName := NULL;
    l_tuCode := NULL;
    l_tuName := NULL;

    /* Если поле "GOST" содержит ГОСТ или ОСТ, то
    заполняется поле "Стандарт на марку".
    Иначе - "Технические условия"
    */
    IF Lower( pkg_importRowMaterialData.GOST ) LIKE '%ост%' THEN
      l_gostOnMarkCode := l_gostCode;
      l_gostOnMarkName := pkg_importRowMaterialData.GOST;

    ELSE
      l_tuCode := l_gostCode;
      l_tuName := pkg_importRowMaterialData.GOST;

    END IF;

    /* заполнение таблицы материалов */
    SELECT materials_code.NEXTVAL INTO l_materialCode FROM dual;

    INSERT INTO materials
    (
    CODE,
    SOCODE,
    PLCODE,
    OKPCODE,
    NAME,
    MATNAME,
    NAMESTD,
    NAMESTD_CODE,
    PROFSTD,
    PROFSTD_CODE,
    TU,
    TU_CODE,
    MEASCODE,
    MEASCODE2,
    MEASCODE3,
    RECDATE,
    OWNER,
    UPDATEDATE,
    UPDATEUSER,
    STATE,
    DOBJCODE,
    NOTICE
    )
    VALUES
    (
    l_materialCode,
    l_businessObjectCode,
    pkg_importRowMaterialData.MAT,
    pkg_importRowMaterialData.OKP,
    pkg_importRowMaterialData.NAIM,
    pkg_importRowMaterialData.MARK,
    l_gostOnMarkName,
    l_gostOnMarkCode,
    pkg_importRowMaterialData.SORM,
    l_sormCode,
    l_tuName,
    l_tuCode,
    l_measCode_1,
    l_measCode_2,
    l_measCode_3,
    l_datv,
    pkg_settings.ownerCode,
    l_dkor,
    pkg_settings.userCode,
    pkg_settings.matState,
    NULL,
    pkg_settings.notice
    );

    /* функционал отключенных триггеров... */
    SELECT sq_stockObj.NEXTVAL INTO l_stockObjCode FROM dual;

    -- номенклатура
    INSERT INTO stockObj
    (code,baseType,baseCode,nomSign)
    VALUES
    (l_stockObjCode, 1, l_materialCode, pkg_importRowMaterialData.MAT);

    -- нулевая цена
    omprices.insert_zero_price( l_stockobjcode, 101 );

    /*
    stockObj.description
    '<NAME>'
    '<MATNAME>'
    '<NAMESTD>'
    '<PROFILE>'
    '<PROFSTD>'

    stockObj.sign
    '<MATNAME>'
    '<PROFILE>'
    '<TU>'
    '<NAMESTD>'
    '<PROFSTD>'
    */

    l_description := Nvl( pkg_importRowMaterialData.NAIM || ' ', '' ) ||
                     Nvl( pkg_importRowMaterialData.MARK || ' ', '' ) ||
                     Nvl( l_gostOnMarkName || ' ', '' ) ||
                     '' ||
                     Nvl( pkg_importRowMaterialData.SORM, '' );

    l_sign := pkg_importRowMaterialData.MARK || ' ' ||
              NULL || ' ' ||
              l_tuName || ' ' ||
              l_gostOnMarkName || ' ' ||
              pkg_importRowMaterialData.SORM;

    UPDATE stockObj SET description = l_description,
                        desc_date = SYSDATE,
                        desc_fmt = NULL,
                        measCode = l_measCode_1,
                        desc_update_check = 0,
                        is_annul = 0,
                        recDate = l_datv,
                        owner = pkg_settings.ownerCode,
                        notice = pkg_settings.notice,
                        attr = NULL,
                        Sign = l_sign,
                        name = pkg_importRowMaterialData.NAIM,
                        unvCode = NULL,
                        mat_state = pkg_settings.matState,
                        soCode = l_businessObjectCode
    WHERE
        code = l_stockObjCode;


--    DELETE FROM t_so_info_record;

--    l_rec_id := so_sign_manager.get_description( l_stockObjCode );
--    OPEN SoInfoRecordCursor( l_rec_id );
--    FETCH SoInfoRecordCursor INTO l_rec;

--    IF l_rec.FOUND IS NOT NULL THEN
--      UPDATE stockobj set description = l_rec.Description, DESC_DATE = sysdate,
--                        DESC_FMT = l_rec.DescFmt, MeasCode = l_rec.MeasCode,DESC_UPDATE_CHECK = 0,
--                        is_annul = nvl(l_rec.is_annul,is_annul),
--                        RECDATE = l_rec.recdate, owner = l_rec.owner, notice = l_rec.notice, attr = l_rec.attr,
--                        SIGN = l_rec.sign, NAME = l_rec.name, UNVCODE = l_rec.unvcode, MAT_STATE = l_rec.MAT_REC_STATE,
--                        SOCODE = l_rec.SoCode
--                        where code = l_stockobjcode;
--    END IF;

--    CLOSE SoInfoRecordCursor;

--    DELETE FROM t_so_info_record;

    /* ---- */

    SELECT sq_materials_states.NEXTVAL INTO l_materialStateCode FROM dual;

    -- статус материала
    INSERT INTO materials_states
    (code,matcode,state,statedate,usercode,note,prevstate)
    VALUES
    (l_materialStateCode, l_materialCode, pkg_settings.matState,
      l_datv, pkg_settings.userCode, NULL, NULL );

    -- история материала
    INSERT INTO xml_history
    (changeDate, xmlDocType, ompCode, sql_type, userCode,
      code, histXML_old2, histXML)
    VALUES
    (l_datv, 1000001, l_materialCode, 2, pkg_settings.userCode,
        sq_xml_history_code.NEXTVAL, NULL, pkg_matHistory );

    -- добавление материала в заданный классификатор
    IF pkg_settings.matClassifyCode IS NOT NULL
      AND
        pkg_importRowMaterialData.GRU IS NOT NULL THEN

      SELECT
        Count(*)
      INTO
        l_groupCode
      FROM
        groups_in_classify
      WHERE
          clCode = pkg_settings.matClassifyCode
        AND
          grCode = pkg_importRowMaterialData.GRU;

      -- если группа в классификаторе не найдена,
      -- то предпринимается попытка найти эту группу и создать
      IF l_groupCode = 0 THEN
        l_groupCode := NULL;

        FOR k IN (
          SELECT
            MAT AS grCode,
            NAIM ||
              CASE
                WHEN MARK IS NOT NULL THEN ' ' || MARK
                ELSE
                  ''
              END ||
              CASE
                WHEN ZVET IS NOT NULL THEN ' ' || ZVET
                ELSE
                  ''
              END AS grName
          FROM
            sepo_maters
          WHERE
              id_load = pkg_importRowMaterialData.id_load
            AND
              mat = gru
            AND
              obozngr IS NULL
        ) LOOP
          l_groupCode := CreateGroup(
            k.grCode,
            k.grName,
            pkg_settings.matClassifyCode,
            3000012
            );

        END LOOP;

      ELSE
        SELECT
          Max(code)
        INTO
          l_groupCode
        FROM
          groups_in_classify
        WHERE
            clCode = pkg_settings.matClassifyCode
          AND
            grCode = pkg_importRowMaterialData.GRU;

      END IF;

      -- если группа существует, то...
      IF l_groupCode IS NOT NULL THEN
        INSERT INTO material_to_group
        VALUES
        (l_materialCode, l_groupCode);

      END IF;

    END IF;

    -- запись в лог
    p_sepo_import_maters_log( pkg_importRowMaterialData.ID, 'OK!');

  EXCEPTION
    WHEN l_existsMaterialException THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Материал с таким кодом уже существует!' );

    WHEN l_unit1_not_exists THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Единица измерения по коду БНМ ' || pkg_importRowMaterialData.EIO || ' не найдена.' );

    WHEN l_unit2_not_exists THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Единица измерения по коду БНМ ' || pkg_importRowMaterialData.EID1 || ' не найдена.' );

    WHEN l_unit3_not_exists THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Единица измерения по коду БНМ ' || pkg_importRowMaterialData.EID2 || ' не найдена.' );

    WHEN l_unsupported_format_date THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! некорректный формат даты.' );

    WHEN OTHERS THEN
--      p_sepo_import_maters_log(
--        pkg_importRowMaterialData.ID,
--        'Непредвиденная ошибка! ' || Chr(10) ||
--          'CreateMaterial: ' ||
--          dbms_utility.format_error_stack || ' ' ||
--          dbms_utility.format_error_backtrace );

      RAISE;

  END;


  /* процедура обновляет атрибуты материалы */
  PROCEDURE UpdateStockItemAttrs( p_objectCode NUMBER )
  IS
    /* переменная для перевода строки в дату по указанному формату */
    l_dateForParam DATE;

  BEGIN
    /* создание атрибутов */
    INSERT INTO obj_attr_values_1000045
    (soCode)
    VALUES
    ( p_objectCode );

    /* далее идет настройка атрибутов и установка значений */
    /* инициализация настроек */
    pkg_sepo_attr_operations.Init( pkg_stockItemTypeCode );

    /* для каждого атрибута вызывается функция привязки значений */
    /* принимает имя атрибута, тип и значение */
    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SKL',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.SKL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CEN',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CEN
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DATA, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DATA',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'POZ1',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.POZ1
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'POZ2',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.POZ2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'GRU',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.GRU
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'NAIM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.NAIM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'MARK',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.MARK
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DIAM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.DIAM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DM',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.DM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CLT',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.CLT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TOL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.TOL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CHIR',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CHIR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.DL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'GOST',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.GOST
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SORM',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.SORM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'KOEF',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.KOEF
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'EID1',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.EID1
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'UDN1',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.EID2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'EID2',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.EID2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'UDN2',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.UDN2
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'VED',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.VED
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRNOM',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PRNOM
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENN',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENN
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SROKX',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.SROKX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRES',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRES
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESB',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESB
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'OKP',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.OKP
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TABN',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.TABN
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRIS',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PRIS
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SER',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.SER
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ZOL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.ZOL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ROD',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.ROD
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PAL',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PAL
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PLAT',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PLAT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PLAT_IR',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.PLAT_IR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ZVET',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.ZVET
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'SORT',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.SORT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENX',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESX',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESX
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PPVK',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.PPVK
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'VPR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.VPR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'OBOZNGR',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.OBOZNGR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'KODGR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.KODGR
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DATV, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DATV',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    l_dateForParam := To_Date(
      Nvl( pkg_importRowMaterialData.DKOR, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'DKOR',
      p_type => DATE_,
      p_value => l_dateForParam
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TABKOR',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.TABKOR
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'OKEI',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.OKEI
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'IMP',
      p_type => INT_,
      p_value => pkg_importRowMaterialData.IMP
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'ORG',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.ORG
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'RUT',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.RUT
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'CENGZ',
      p_type => DOUBLE_,
      p_value => pkg_importRowMaterialData.CENGZ
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'PRESGZ',
      p_type => STRING_,
      p_value => pkg_importRowMaterialData.PRESGZ
    );

    /* ... и обновление заданных атрибутов */
    pkg_sepo_attr_operations.UpdateAttrs( p_objectCode );

    /* сброс настроек */
    pkg_sepo_attr_operations.Clear();

  END;

  FUNCTION IsExistsItem RETURN BOOLEAN
  IS
    l_count NUMBER;

  BEGIN

    SELECT
      Count(*)
    INTO
      l_count
    FROM
      stock_other
    WHERE
        sign = To_Char( pkg_importRowMaterialData.MAT );

    RETURN ( l_count > 0 );

  END;

  PROCEDURE CreateOtherItem
  IS
    l_businessObjectCode NUMBER;
    l_existsItemException EXCEPTION;
    l_measCode_1 NUMBER;
    l_stockObjCode NUMBER;

    l_stockItemName stockobj.name%TYPE;

--    CURSOR SoInfoRecordCursor ( rec_id in integer ) is
--      SELECT T.*, count(1) over() as FOUND FROM T_SO_INFO_RECORD T WHERE id = rec_id;
--    l_rec SoInfoRecordCursor%ROWTYPE;
--    l_rec_id INTEGER;

    l_existsStockItemException EXCEPTION;
    l_unit1_not_exists EXCEPTION;
    l_unsupported_format_date EXCEPTION;

  BEGIN
    IF IsExistsItem THEN
      RAISE l_existsStockItemException;

    END IF;

    l_measCode_1 := GetOmegaUnit(pkg_importRowMaterialData.EIO);
    IF l_measCode_1 = -1 THEN
      RAISE l_unit1_not_exists;

    END IF;

    /* проверка формата дат */
    /* должен быть формат DD.MM.YYYY */
    IF pkg_importRowMaterialData.DATV IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DATV,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;

    IF pkg_importRowMaterialData.DKOR IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DKOR,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;

    IF pkg_importRowMaterialData.DKOR IS NOT NULL AND
      NOT regexp_like( pkg_importRowMaterialData.DATA,
                  '(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d'
                  )
                  THEN

                  RAISE  l_unsupported_format_date;

    END IF;


    SELECT sq_business_objects_code.NEXTVAL INTO l_businessObjectCode FROM dual;

    INSERT INTO omp_objects
    (code,objType,scheme,num)
    VALUES
    (l_businessObjectCode, pkg_stockItemTypeCode, NULL, so.GetNextSoNum);

    UpdateStockItemAttrs( l_businessObjectCode );

    l_stockItemName := pkg_importRowMaterialData.NAIM || ' / ' ||
                        pkg_importRowMaterialData.MARK || ' / ' ||
                        pkg_importRowMaterialData.GOST || ' / ' ||
                        pkg_importRowMaterialData.SORM;

    IF Nvl(pkg_importRowMaterialData.DM, 0 ) > 0
      OR
        Nvl(pkg_importRowMaterialData.DL, 0 ) > 0
      OR
        Nvl(pkg_importRowMaterialData.CHIR, 0 ) > 0
      OR
        Nvl(pkg_importRowMaterialData.TOL, 0 ) > 0

        THEN l_stockItemName := l_stockItemName || ' / ' ||
                        pkg_importRowMaterialData.DM || ' / ' ||
                        pkg_importRowMaterialData.DL || ' / ' ||
                        pkg_importRowMaterialData.CHIR || ' / ' ||
                        pkg_importRowMaterialData.TOL;

    END IF;


    INSERT INTO stock_other
    (CODE,
    SIGN,
    NAME,
    MEASCODE,
    OWNER,
    RECDATE,
    BASETYPE,
    BASECODE,
    IS_ANNUL,
    NOTICE)
    VALUES
    (l_businessObjectCode,
    pkg_importRowMaterialData.MAT,
    l_stockItemName,
    l_measCode_1,
    pkg_settings.ownerCode,
    To_Date(
      Nvl( pkg_importRowMaterialData.DATV, To_Char(SYSDATE, 'dd.mm.yyyy') ),
      'dd.mm.yyyy' ),
    -1,
    0,
    0,
    pkg_settings.notice);

     /* функционал отключенных триггеров... */
    SELECT sq_stockObj.NEXTVAL INTO l_stockObjCode FROM dual;

    INSERT INTO stockObj
    (code,baseType,baseCode)
    VALUES
    (l_stockObjCode, 2, l_businessObjectCode);

    UPDATE stockObj SET description = pkg_importRowMaterialData.MAT || ' ' || l_stockItemName,
                        desc_date = SYSDATE,
                        desc_fmt = NULL,
                        measCode = l_measCode_1,
                        desc_update_check = 0,
                        is_annul = 0,
                        recDate = To_Date( coalesce( pkg_importRowMaterialData.DATV,
                          To_Char(SYSDATE, 'dd.mm.yyyy') ), 'dd.mm.yyyy' ),
                        owner = pkg_settings.ownerCode,
                        notice = pkg_settings.notice,
                        attr = NULL,
                        Sign = pkg_importRowMaterialData.MAT,
                        name = pkg_importRowMaterialData.NAIM,
                        unvCode = NULL,
                        mat_state = pkg_settings.matState,
                        soCode = l_businessObjectCode
    WHERE
        code = l_stockObjCode;

--    DELETE FROM t_so_info_record;

--    l_rec_id := so_sign_manager.get_description( l_stockObjCode );
--    OPEN SoInfoRecordCursor( l_rec_id );
--    FETCH SoInfoRecordCursor INTO l_rec;

--    IF l_rec.FOUND IS NOT NULL THEN
--      UPDATE stockobj set description = l_rec.Description, DESC_DATE = sysdate,
--                        DESC_FMT = l_rec.DescFmt, MeasCode = l_rec.MeasCode,DESC_UPDATE_CHECK = 0,
--                        is_annul = nvl(l_rec.is_annul,is_annul),
--                        RECDATE = l_rec.recdate, owner = l_rec.owner, notice = l_rec.notice, attr = l_rec.attr,
--                        SIGN = l_rec.sign, NAME = l_rec.name, UNVCODE = l_rec.unvcode, MAT_STATE = l_rec.MAT_REC_STATE,
--                        SOCODE = l_rec.SoCode
--                        where code = l_stockObjCode;
--    END IF;

--    CLOSE SoInfoRecordCursor;

--    DELETE FROM t_so_info_record;

    p_sepo_import_maters_log( pkg_importRowMaterialData.ID, 'OK!');

  EXCEPTION
    WHEN l_existsStockItemException THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! ТМЦ с таким кодом уже существует!' );

    WHEN l_unit1_not_exists THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Единица измерения по коду БНМ ' || pkg_importRowMaterialData.EIO || ' не найдена.' );

    WHEN l_unsupported_format_date THEN
      p_sepo_import_maters_log(
        pkg_importRowMaterialData.ID,
        'Ошибка! Некорректный формат даты.' );

    WHEN OTHERS THEN
--      p_sepo_import_maters_log(
--        pkg_importRowMaterialData.ID,
--        'Непредвиденная ошибка! ' || Chr(10) ||
--          'CreateMaterial: ' ||
--          dbms_utility.format_error_stack || ' ' ||
--          dbms_utility.format_error_backtrace );

      RAISE;

  END;

  -- начало истории материала
  PROCEDURE WriteMatHistory
  IS
    l_histClob CLOB;
  BEGIN
    l_histClob :=
    '<OmegaProduction>' || Chr(10) ||
	  '  <Материал>' || Chr(10) ||
	  '	  <CO>' || Chr(10) ||
	  '	  </CO>' || Chr(10) ||
	  '  </Материал>' || Chr(10) ||
    '</OmegaProduction>';

    FOR i IN (
      SELECT * FROM materials m
      WHERE
          m.updateUser = -2
        AND
          NOT EXISTS
          (
            SELECT 1 FROM xml_history h
            WHERE
                h.xmlDocType = 1000001
              AND
                h.sql_type = 2
              AND
                h.ompCode = m.code

          )
    ) LOOP

      INSERT INTO xml_history
      (changeDate, xmlDocType, ompCode, sql_type, userCode,
        code, histXML_old2, histXML)
      VALUES
      (i.recDate, 1000001, i.code, 2, i.updateUser,
        sq_xml_history_code.NEXTVAL, NULL, l_histClob );

    END LOOP;

  END;

  -- начала истории ТМЦ
  PROCEDURE WriteOIHistory
  IS
    l_histClob CLOB;
  BEGIN
    l_histClob :=
    '<OmegaProduction>' || Chr(10) ||
	  '  <ТМЦ>' || Chr(10) ||
	  '	  <CO>' || Chr(10) ||
	  '	  </CO>' || Chr(10) ||
	  '  </ТМЦ>' || Chr(10) ||
    '</OmegaProduction>';

    FOR i IN (
      SELECT * FROM stock_other s
      WHERE
          recUser = -2
        AND
          NOT EXISTS
          (
            SELECT 1 FROM xml_history h
            WHERE
                h.xmlDocType = 1000045
              AND
                h.sql_type = 2
              AND
                h.ompCode = s.code

          )
    ) LOOP

      INSERT INTO xml_history
      (changeDate, xmlDocType, ompCode, sql_type, userCode,
        code, histXML_old2, histXML)
      VALUES
      (i.recDate, 1000045, i.code, 2, i.recUser,
        sq_xml_history_code.NEXTVAL, NULL, l_histClob );

    END LOOP;
  END;

  PROCEDURE AddGroups( p_clCode NUMBER )
  IS
    l_clType NUMBER;
    l_groupCode NUMBER;
  BEGIN
    SELECT
      clType + 3000000
    INTO
      l_clType
    FROM
      classify
    WHERE
        code = p_clCode;

    FOR i IN (
      SELECT
        MAT AS grCode,
        NAIM ||
          CASE
            WHEN MARK IS NOT NULL THEN ' ' || MARK
            ELSE
              ''
          END ||
          CASE
            WHEN ZVET IS NOT NULL THEN ' ' || ZVET
            ELSE
              ''
          END AS grName
      FROM
        sepo_maters
      WHERE
          mat = gru
        AND
          obozngr IS NULL
    ) LOOP
      l_groupCode := CreateGroup(
        i.grCode,
        i.grName,
        p_clCode,
        l_clType
        );

    END LOOP;

  END;

  PROCEDURE AddMaterials( p_clCode NUMBER )
  IS
  BEGIN
    INSERT INTO material_to_group
    SELECT
      mats.code,
      gr.code
    FROM
      materials mats,
      sepo_maters dbf,
      groups_in_classify gr
    WHERE
        mats.plCode = dbf.MAT
      AND
        gr.clCode = p_clCode
      AND
        dbf.GRU = gr.grCode;

  END;

  PROCEDURE AddStockObj( p_clCode NUMBER )
  IS

  BEGIN
    INSERT INTO stockobj_to_group
    SELECT
      obj.code,
      gr.code
    FROM
      stockobj obj,
      sepo_maters dbf,
      groups_in_classify gr
    WHERE
        obj.sign = To_Char(dbf.MAT)
      AND
        obj.baseType = 2
      AND
        gr.clCode = p_clCode
      AND
        dbf.GRU = gr.grCode;
  END;

  PROCEDURE CreateMatClassify( p_name VARCHAR2 )
  IS
    l_soCode NUMBER;
    l_classify NUMBER;
  BEGIN
    l_soCode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects
    (code, objType, num)
    VALUES
    (l_soCode, 3000012, so.GetNextSoNum() );

    INSERT INTO obj_attr_values_3000012
    (soCode)
    VALUES
    (l_soCode);

    l_classify := sq_classify.NEXTVAL;

    INSERT INTO classify
    (code, clCode, clType, clName, owner)
    VALUES
    (l_classify, p_name, 12, p_name, pkg_settings.ownerCode);

    AddGroups(l_classify);
    AddMaterials(l_classify);

  END;

  PROCEDURE CreateTMCClassify( p_name VARCHAR2 )
  IS
    l_soCode NUMBER;
    l_classify NUMBER;
  BEGIN
    l_soCode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects
    (code, objType, num)
    VALUES
    (l_soCode, 3000034, so.GetNextSoNum() );

    INSERT INTO obj_attr_values_3000012
    (soCode)
    VALUES
    (l_soCode);

    l_classify := sq_classify.NEXTVAL;

    INSERT INTO classify
    (code, clCode, clType, clName, owner)
    VALUES
    (l_classify, p_name, 34, p_name, pkg_settings.ownerCode);

    AddGroups(l_classify);
    AddStockObj(l_classify);
  END;

  PROCEDURE LoadMixture
  IS
  BEGIN
    FOR i IN (
      SELECT
        sl.*,
        ssl.snr,
        CASE
          WHEN coalesce(sl.nr, 0 ) = 0 THEN prc / 100
          ELSE
            sl.nr / ssl.snr
        END AS omp_nr,
        mix.code AS omp_mix,
        mix.name AS omp_mix_name,
        elem.code AS omp_elem,
        elem.name AS omp_elem_name,
        elem.measCode AS omp_elem_unit,
        ssl.isFullMix
      FROM
        sepo_lit sl,
        materials mix,
        materials elem,
        (
          SELECT
            sl.shm,
            Sum(coalesce(sl.nr, 0)) AS snr,
            Min(
            CASE
              WHEN elem.code IS NOT NULL THEN 1
              ELSE
                0
            END) AS isFullMix
          FROM
            sepo_lit sl,
            materials elem
          WHERE
              sl.shk = elem.plCode(+)
          GROUP BY
            sl.shm
        ) ssl
      WHERE
          sl.shm = ssl.shm
        AND
          sl.shm = mix.plCode(+)
        AND
          sl.shk = elem.plCode(+)
        AND
          ssl.isFullMix = 1
        AND
          mix.code IS NOT NULL
        AND
          NOT EXISTS
          (
            SELECT 1 FROM mix_materials mix_
            WHERE
                mix_.mixCode = mix.code
              AND
                mix_.matCode = elem.code
          )
    ) LOOP
      UPDATE materials SET matType = 3
      WHERE
          code = i.omp_mix;

      INSERT INTO mix_materials
      (code, mixcode, matcode, norm, meascode, state,
         recdate, changeDate, userCode)
      VALUES
      (sq_mix_materials.NEXTVAL, i.omp_mix, i.omp_elem,
        i.omp_nr, i.omp_elem_unit, 1, SYSDATE, SYSDATE, -2);

    END LOOP;

  END;

END;
/