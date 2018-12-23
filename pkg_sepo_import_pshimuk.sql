PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_import_pshimuk
CREATE OR REPLACE PACKAGE pkg_sepo_import_pshimuk
AS
  -- строка импорта
  pkg_importRowData view_sepo_pshimuk%ROWTYPE;

  NORM_STATE_UNCONFIRMED CONSTANT NUMBER := 1;
  NORM_STATE_CONFIRMED CONSTANT NUMBER := 0;
  NORM_STATE_ANNUL CONSTANT NUMBER := 3;

  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_normStatus NUMBER DEFAULT NORM_STATE_CONFIRMED,
    p_notice stockObj.notice%TYPE DEFAULT NULL
  );
  PROCEDURE Clear;
  -- проверка данных
  PROCEDURE CheckData;
  -- добавление материала на элемент
  PROCEDURE AddMaterial;
  -- создание нормы расхода основного материала
  PROCEDURE CreateMainNorm;

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_pshimuk
CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_pshimuk
AS
  -- настройки импорта
  TYPE ImportSettings IS RECORD (
    userCode NUMBER,
    userName user_list.loginName%TYPE,
    ownerCode NUMBER,
    ownerName owner_name.name%TYPE,
    normStatus NUMBER,
    notice stockObj.notice%TYPE
  );
  pkg_settings ImportSettings;

  -- данные о связи элемента с материалом
  TYPE KoLinkMatData IS RECORD (
    soKoCode NUMBER, -- код объекта системы для КЭ
    koCode NUMBER, -- код КЭ
    koType NUMBER, -- тип КЭ
    soMatCode NUMBER, -- код объекта системы для материала
    matCode NUMBER, -- код материала
    isMain NUMBER, -- признак: основной или заменитель
    isAddMaterial BOOLEAN, -- признак: указывает, добавлять ли материал на элемент
    isCreatingNorm BOOLEAN -- признак: указывает, создавать ли норму расхода
  );
  pkg_koLinkMatData KoLinkMatData;

  -- очищение настроек
  PROCEDURE Clear
  IS

  BEGIN
    pkg_settings := NULL;
    pkg_koLinkMatData := NULL;

  END;

  -- инициализация настроек
  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_normStatus NUMBER,
    p_notice stockObj.notice%TYPE DEFAULT NULL
  )
  IS
    l_count NUMBER;

    l_user_not_exists EXCEPTION;
    l_owner_not_exists EXCEPTION;

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

    pkg_settings.ownerName := p_ownerName;
    pkg_settings.normStatus := p_normStatus;
    pkg_settings.notice := p_notice;

  EXCEPTION
    WHEN l_user_not_exists THEN
      Raise_Application_Error( -20103, 'Ошибка! Пользователя ' || p_userName || ' не существует' );
    WHEN l_owner_not_exists THEN
      Raise_Application_Error( -20103, 'Ошибка! Владельца ' || p_ownerName || ' не существует' );
    WHEN OTHERS THEN
      RAISE;

  END;

  -- лог импорта
  procedure p_sepo_import_pshimuk_log ( id NUMBER, message VARCHAR2 )
  AS
    pragma autonomous_transaction;
    begin
    INSERT INTO sepo_import_pshimuk_log
    VALUES
    ( id, message, SYSDATE );

    COMMIT;

  end;

  /* получение единиц измерения по коду БНМ */
  FUNCTION GetOmegaUnit( p_unitBNMCode NUMBER )
  RETURN NUMBER
  IS
    l_omegaUnitCode NUMBER;
    l_count NUMBER;

    l_unit_not_exists EXCEPTION;

  BEGIN
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

  -- предварительная проверка данных
  PROCEDURE CheckData
  IS
    l_isExistsMaterial BOOLEAN;
    l_count NUMBER;

    l_dceNotExists EXCEPTION;
    l_matNotExists EXCEPTION;
    l_matAddedOnDce EXCEPTION;

  BEGIN
    -- в начале получает все данные о материале и конструкторском элементе
    pkg_koLinkMatData := NULL;

    -- если дсе не найдена, то ошибка...
    IF pkg_importRowData.dceSoCode IS NULL THEN
      RAISE l_dceNotExists;
    END IF;

    pkg_koLinkMatData.soKoCode := pkg_importRowData.dceSoCode;
    pkg_koLinkMatData.koCode := pkg_importRowData.dceCode;
    pkg_koLinkMatData.koType := pkg_importRowData.dceType;

    -- если материал не найден, то ошибка...
    IF pkg_importRowData.matCode IS NULL THEN
      RAISE l_matNotExists;
    END IF;

    pkg_koLinkMatData.matCode := pkg_importRowData.matCode;
    pkg_koLinkMatData.soMatCode := pkg_importRowData.matSoCode;

    -- проверка, задан ли текущий материал на текущей дсе
    SELECT
      Count(*)
    INTO
      l_count
    FROM
      main_materials
    WHERE
        unvCode = pkg_koLinkMatData.koCode
      AND
        matCode = pkg_koLinkMatData.matCode;

    -- если задан, то ошибка в файле, дублирование нормы
    IF l_count > 0 THEN RAISE l_matAddedOnDce; END IF;

    -- проверка, заданы ли материалы на дсе
    SELECT
      Count(*)
    INTO
      l_count
    FROM
      main_materials
    WHERE
        unvCode = pkg_koLinkMatData.koCode;

    -- если на дсе нет материалов, то текущий материал - основной;
    -- иначе - заменитель
    IF l_count > 0 THEN
      pkg_koLinkMatData.isMain := 0;
    ELSE
      pkg_koLinkMatData.isMain := 1;
    END IF;

    -- если проверка прошла успешно, то далее добавляется материал
    -- и создается норма расхода.
    -- в противном случае - переход на следующую позицию
    pkg_koLinkMatData.isAddMaterial := TRUE;
    pkg_koLinkMatData.isCreatingNorm := TRUE;

  EXCEPTION
    WHEN l_dceNotExists THEN
      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ERROR: Не найдена ДСЕ с кодом ' || pkg_importRowData.DCE );

      pkg_koLinkMatData.isAddMaterial := FALSE;
      pkg_koLinkMatData.isCreatingNorm := FALSE;

    WHEN l_matNotExists THEN
      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ERROR: Не найден материал с кодом ' || pkg_importRowData.SHM );

      pkg_koLinkMatData.isAddMaterial := FALSE;
      pkg_koLinkMatData.isCreatingNorm := FALSE;

    WHEN l_matAddedOnDce THEN
      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ERROR: Материал ' || pkg_importRowData.SHM ||
        ' уже добавлен ' || ' на ДСЕ ' || pkg_importRowData.DCE ||
        '. Норма дублируется в файле' );

      pkg_koLinkMatData.isAddMaterial := FALSE;
      pkg_koLinkMatData.isCreatingNorm := FALSE;

    WHEN OTHERS THEN
      RAISE;

  END;

  -- обновление материала в стандартной таблице для деталей
  PROCEDURE UpdateDetail( p_soKoCode NUMBER, p_koCode NUMBER, p_matCode NUMBER )
  IS
    l_soMatCode NUMBER;
  BEGIN
    UPDATE details SET matCode = p_matCode WHERE code = p_koCode;

    SELECT
      soCode
    INTO
      l_soMatCode
    FROM
      materials
    WHERE
     code = p_matCode;

    pkg_sepo_attr_operations.Init(2);

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'Материал',
      p_type => 6,
      p_value => l_soMatCode
    );

    pkg_sepo_attr_operations.UpdateAttrs( p_soKoCode );
    pkg_sepo_attr_operations.Clear();

  END;

  -- обновление материала в таблице для стандартных изделий
  PROCEDURE UpdateStd( p_koCode NUMBER, p_matCode NUMBER )
  IS

  BEGIN
    UPDATE standarts SET matCode = p_matCode
    WHERE
        code = p_koCode;

  END;

  -- обновление материала в таблице сборочных материалов
  PROCEDURE UpdateSpcMaterial( p_koCode NUMBER, p_matCode NUMBER )
  IS

  BEGIN
    UPDATE spcMaterials SET matCode = p_matCode
    WHERE
        code = p_koCode;

  END;

  -- добавляет материал на дсе
  PROCEDURE AddMaterial
  IS
    l_main_material_code NUMBER;

  BEGIN
    IF pkg_koLinkMatData.isAddMaterial THEN
      SELECT sq_main_materials.NEXTVAL INTO l_main_material_code FROM dual;

      INSERT INTO main_materials
      (
      code,
      unvCode,
      matCode,
      markCode,
      is_main,
      is_change_act,
      priority,
      right_type,
      purpose,
      recalc,
      enterprise,
      is_substmat,
      changed_by_card,
      main_block_mat,
      color_schema,
      rec_date
      )
      VALUES
      (
      l_main_material_code,
      pkg_koLinkMatData.koCode,
      pkg_koLinkMatData.matCode,
      NULL,
      pkg_koLinkMatData.isMain,
      0,
      Nvl( pkg_importRowData.PRM, 0 ) + 1,
      0,
      NULL,
      0,
      NULL,
      0,
      0,
      NULL,
      NULL,
      SYSDATE
      );

      IF pkg_koLinkMatData.isMain = 1 THEN
        IF pkg_koLinkMatData.koType = 2 THEN
          UpdateDetail(
            pkg_koLinkMatData.soKoCode,
            pkg_koLinkMatData.koCode,
            pkg_koLinkMatData.matCode
            );

        ELSIF pkg_koLinkMatData.koType = 3 THEN
          UpdateStd(
            pkg_koLinkMatData.koCode,
            pkg_koLinkMatData.matCode
            );

        ELSIF pkg_koLinkMatData.koType = 5 THEN
          UpdateSpcMaterial(
            pkg_koLinkMatData.koCode,
            pkg_koLinkMatData.matCode
            );

        END IF;


      END IF;

      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ОК! Материал  ' || pkg_importRowData.SHM ||
        ' успешно добавлен на ДСЕ ' || pkg_importRowData.DCE );

    END IF;


  END;

  -- обновление атрибутов на норме расхода
  PROCEDURE UpdateAttrsOnNorm( p_soCode NUMBER, p_matData materials%ROWTYPE )
  IS

  BEGIN
    INSERT INTO obj_attr_values_1000000
    (soCode)
    VALUES
    (p_soCode);

    /*
    INSERT  INTO OBJ_ATTR_VALUES_1000000
    (SOCODE,A_189,A_189_IS_CALC,A_190,A_190_IS_CALC,A_191,A_191_IS_CALC,A_194,A_194_IS_CALC,A_199_IS_CALC,A_201,A_201_IS_CALC,
    A_202,A_202_IS_CALC,A_207_IS_CALC,A_208_IS_CALC,A_209_IS_CALC,A_211_IS_CALC,A_1500_IS_CALC,
    A_1581,A_2524,A_2540,A_2541,A_2941,M_2941,A_2942,M_2942,A_6399,A_6399_IS_CALC,
    A_6400,A_6401,A_6401_IS_CALC,A_6402,A_6402_IS_CALC,A_6403,A_6403_IS_CALC,A_6404,A_7082)
    VALUES (:1,:2,:3,:4,:5,:6,:7, NULL ,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,
    NULL , NULL , NULL , NULL ,:20, NULL ,:21,:22,:23, NULL , NULL ,:24, NULL ,
    :25,:26,:27, NULL , NULL )
    */
    pkg_sepo_attr_operations.Init(1000000);

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'НаимВычисл',
      p_type => 1,
      p_value => p_matData.name,
      p_meas => NULL,
      p_calc => 0
    );

    pkg_sepo_attr_operations.AddAttrData (
      p_name => 'TABN',
      p_type => 3,
      p_value => pkg_importRowData.TABN
    );

    pkg_sepo_attr_operations.UpdateAttrs( p_soCode );

  END;

  -- создание нормы
  PROCEDURE CreateMainNorm
  IS
    l_soCode NUMBER;
    l_normCode NUMBER;
    l_matData materials%ROWTYPE;
    l_measCode_1 NUMBER;

    l_unit_not_exists EXCEPTION;
    l_larger_value_zag_weight EXCEPTION;

  BEGIN
    IF pkg_koLinkMatData.isCreatingNorm THEN
      SELECT sq_business_objects_code.NEXTVAL INTO l_soCode FROM dual;
      SELECT * INTO l_matData FROM materials WHERE code = pkg_koLinkMatData.matCode;

      INSERT INTO omp_objects
      VALUES
      ( l_soCode, 1000000, NULL, so.getNextSoNum() );

      UpdateAttrsOnNorm( l_soCode, l_matData );

      SELECT det_expense_normcode.NEXTVAL INTO l_normCode FROM dual;
      l_measCode_1 := GetOmegaUnit(pkg_importRowData.ED);

      IF Nvl(l_measCode_1, -1) = -1 THEN RAISE l_unit_not_exists; END IF;
      IF pkg_importRowData.NR > 999999 THEN RAISE l_larger_value_zag_weight; END IF;

      INSERT INTO det_expense
      (
      normcode,
      socode,
      detcode,
      dettype,
      coop,
      zagsize,
      rodcut,
      endcut,
      shtangcut,
      suppression,
      pureweightmeas,
      billetlen,
      pours_gains,
      zagdetnum,
      zagweight,
      pourweight,
      adjextra_prc,
      adjextra_kg,
      pureweight,
      dobjcode,
      dobjcode2,
      dobjcode3,
      matcode,
      markcode,
      dobj_section,
      matsize,
      orderform,
      fullnorm1,
      itemnorm1,
      measure1,
      detwasteuse_prc1,
      sparewasteuse_prc1,
      calcexpensenorm1,
      fullnorm2,
      itemnorm2,
      measure2,
      calcexpensenorm2,
      waste_shaving,
      waste_carving,
      normstatus,
      waste_obloy,
      waste_end,
      waste_all,
      style_ex,
      groupcode,
      lastuser,
      recdate,
      changedate,
      notice,
      enterprise,
      allow_gosts,
      normtype,
      tpcode,
      tpopercode,
      startdate,
      ppindex,
      archivedate,
      zagweightmeas,
      waste_meas,
      billet_norm,
      changed_by_card,
      mat_type,
      inccode,
      appcode,
      hroute_code,
      color_code,
      order_code,
      orderrow_code
      )
      VALUES
      (
      l_normCode,
      l_soCode,
      pkg_koLinkMatData.koCode,
      pkg_koLinkMatData.koType,
      0,
      NULL,
      0,
      0,
      0,
      0,
      l_measCode_1,
      0,
      0,
      0,
      pkg_importRowData.NR,
      0,
      0,
      0,
      pkg_importRowData.CHV,
      pkg_importRowData.CEX,
      NULL,
      NULL,
      pkg_koLinkMatData.matCode,
      NULL,
      NULL,
      NULL,
      NULL,
      pkg_importRowData.NR,
      0,
      l_measCode_1,
      0,
      0,
      0,
      NULL,
      0,
      NULL,
      0,
      0,
      0,
      pkg_settings.normStatus,
      0,
      0,
      0,
      pkg_koLinkMatData.isMain,
      NULL,
      pkg_settings.userCode,
      Nvl(To_Date(pkg_importRowData.DATAVK, 'DD.MM.YYYY'), SYSDATE ),
      Nvl(To_Date(pkg_importRowData.DATAVK, 'DD.MM.YYYY'), SYSDATE ),
      pkg_settings.notice,
      NULL,
      NULL,
      0,
      NULL,
      NULL,
      Nvl(To_Date(pkg_importRowData.DATAVK, 'DD.MM.YYYY'), SYSDATE ),
      NULL,
      NULL,
      l_measCode_1,
      101,
      NULL,
      0,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL
      );

      INSERT INTO det_expense_history
      (
      normcode,
      start_user,
      start_reason,
      start_date
      )
      VALUES
      (
      l_normCode,
      pkg_settings.userCode,
      NULL,
      Nvl(To_Date(pkg_importRowData.DATAVK, 'DD.MM.YYYY'), SYSDATE ));

--      UPDATE OBJ_ATTR_VALUES_1000000   SET A_2541= NULL  WHERE SOCODE=:1
--      UPDATE DET_EXPENSE   SET STYLE_EX = BITOR ( STYLE_EX, OMNORM.DES_ACTIVE() )  WHERE  NORMCODE IN (:1);

      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ОК! Норма расхода материала ' || pkg_importRowData.SHM ||
        ' успешно добавлена на ДСЕ ' || pkg_importRowData.DCE);

    END IF;

  EXCEPTION
    WHEN l_larger_value_zag_weight THEN
      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ERROR: ' || pkg_importRowData.NR || ' - слишком большое значение для поля "Вес заготовки"');
    WHEN l_unit_not_exists THEN
      p_sepo_import_pshimuk_log( pkg_importRowData.ID,
        'ERROR: Не найдена единица измерения по коду БНМ ' || pkg_importRowData.ED);

--    WHEN OTHERS THEN
--      RAISE;

  END;


END;
/

