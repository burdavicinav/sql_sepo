CREATE OR REPLACE PACKAGE pkg_sepo_import_fail2
AS
  pkg_importRow view_sepo_fail2_import%ROWTYPE;

  CONST_ROUTE_STATE_UNCONFIRMED CONSTANT NUMBER := 0;
  CONST_ROUTE_STATE_CONFIRMED CONSTANT NUMBER := 1;
  /*
  p_user_name - логин
  p_owner_name - владелец
  p_routeStatus - статус маршрута
  p_notice - примечание
  */
  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_routeStatus NUMBER,
    p_notice stockObj.notice%TYPE DEFAULT NULL
  );
  /* сброс настроек */
  PROCEDURE Clear;
  /* выгрузка состава маршрута из файла импорта */
  PROCEDURE LoadRouteFromFile;
  /* осуществляет связь цехов из файла с пунктами маршрутов */
  PROCEDURE CexFileToDistricts;
  /* удаление всех маршрутов из Омеги */
  PROCEDURE DeleteAllRoutes;
  /* удаление загруженных данных из файла импорта */
  PROCEDURE DeleteLoadFileData;

  /* создание маршрута */
  PROCEDURE CreateRoute;

END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_fail2
AS
  /* настройки */
  TYPE ImportSettings IS RECORD (
    userCode NUMBER,
    userName user_list.loginName%TYPE,
    ownerCode NUMBER,
    ownerName owner_name.name%TYPE,
    routeStatus NUMBER,
    notice stockObj.notice%TYPE
  );

  /* объект настроек */
  pkg_settings ImportSettings;

  TYPE RouteData IS RECORD (
    createDate DATE,
    modifyDate DATE,
    measCode NUMBER
  );

  pkg_routeData RouteData;


  PROCEDURE Clear
  IS

  BEGIN
    pkg_settings := NULL;
    pkg_routeData := NULL;

  END;

  PROCEDURE Init(
    p_userName user_list.loginName%TYPE,
    p_ownerName owner_name.name%TYPE,
    p_routeStatus NUMBER,
    p_notice stockObj.notice%TYPE DEFAULT NULL
  )
  IS
    l_count NUMBER;

    l_user_not_exists EXCEPTION;
    l_owner_not_exists EXCEPTION;
    l_meas_not_exists EXCEPTION;

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
    pkg_settings.routeStatus := p_routeStatus;
    pkg_settings.notice := p_notice;

    SELECT
      Count(code)
    INTO
      l_count
    FROM
      measures
    WHERE
        shortName = 'ШТ.';

    IF l_count = 0 THEN RAISE l_meas_not_exists; END IF;

    SELECT
      code
    INTO
      pkg_routeData.measCode
    FROM
      measures
    WHERE
        shortName = 'ШТ.';

  EXCEPTION
    WHEN l_user_not_exists THEN
      Raise_Application_Error( -20103, 'Ошибка! Пользователя ' || p_userName || ' не существует' );
    WHEN l_owner_not_exists THEN
      Raise_Application_Error( -20104, 'Ошибка! Владельца ' || p_ownerName || ' не существует' );
    WHEN l_meas_not_exists THEN
      Raise_Application_Error( -20105, 'Ошибка! Единицы измерения "ШТ." не найдена');
    WHEN OTHERS THEN
      RAISE;
  END;

  PROCEDURE LoadRouteFromFile
  IS

  BEGIN
    DELETE FROM sepo_fail2_routes;

    INSERT INTO sepo_fail2_routes
    SELECT
      NULL,
      id,
      To_Number(
          Substr(cexNumber, 4, Length(cexNumber) - 3)
          ) AS cexNumber,
        cexCode
      FROM
        sepo_fail2 data
      unpivot include nulls
      (cexCode FOR cexNumber IN (
        CEX1, CEX2, CEX3, CEX4,
        CEX5, CEX6, CEX7, CEX8,
        CEX9, CEX10, CEX11, CEX12,
        CEX13, CEX14, CEX15, CEX16,
        CEX17, CEX18, CEX19, CEX20,
        CEX21, CEX22, CEX23, CEX24)
        )
    WHERE
        coalesce(cexCode,0) > 0;

  END;

  PROCEDURE CexFileToDistricts
  IS
    l_distNull NUMBER;
  BEGIN
    SELECT
      Max(code)
    INTO
      l_distNull
    FROM
      districts
    WHERE
        shortName = '999';

    IF l_distNull IS NULL THEN Raise_Application_Error(
      -20110, 'Не найден пункт маршрута с кодом 999'
      );
    END IF;

    DELETE FROM sepo_cex_to_district;

    INSERT INTO sepo_cex_to_district
    SELECT
      fail2.cex AS cexCode,
      coalesce(d.code,l_distNull) AS districtCode
    FROM
      ( SELECT DISTINCT cex FROM sepo_fail2_routes ) fail2,
      districts d
    WHERE
        To_Char(fail2.cex) = d.shortName(+);

  END;

  PROCEDURE DeleteAllRoutes
  IS

  BEGIN
    DELETE FROM routes;
    DELETE FROM handle_routes;
    DELETE FROM routeItems;

  END;

  PROCEDURE DeleteLoadFileData
  IS

  BEGIN
    DELETE FROM sepo_cex_to_district;
    DELETE FROM sepo_fail2_routes;

  END;

  PROCEDURE p_sepo_import_fail2_log ( id NUMBER, message VARCHAR2 )
  AS
    pragma autonomous_transaction;
    begin
    INSERT INTO sepo_import_fail2_log
    VALUES
    ( id, message, SYSDATE );

    COMMIT;

  end;

  /* переводит поле даты из строки в формат даты "DD.MM.YYYY" */
  /* поддерживает форматы "DD.MM.YYYY" и "YYYYMMDD" */
  /* в других файлах могут быть и другие форматы, */
  /* хотя если будет DBF, то проблем не должно быть */
  FUNCTION StringToDate(dateString VARCHAR2)
  RETURN DATE
  IS
    dateFormating DATE;
  BEGIN
    IF regexp_like(dateString,
      '^(([012][0-9])|(3[01]))\.((0[1-9])|(1[0-2]))\.[12]\d{3}$') THEN

      RETURN To_Date(dateString,'DD.MM.YYYY');

    ELSIF regexp_like(dateString,
      '^[12]\d{3}((0[1-9])|(1[0-2]))(([012][0-9])|(3[01]))$') THEN

      dateFormating := To_Date(dateString,'YYYYMMDD');
      RETURN To_Date( To_Char(dateFormating,'DD.MM.YYYY'), 'DD.MM.YYYY');

    ELSE
      RETURN NULL;

    END IF;

  END;

  -- создает запись в БД о составе маршрута.
  -- ВНИМАНИЕ: можно запускать только при заполненной
  -- таблице t_omroutes_route_items. Ради оптимизации
  -- импорта.
  FUNCTION CreateStructureRoute(p_hashRoute VARCHAR2 )
  RETURN NUMBER
  IS
    l_sq_handle_routes_code NUMBER;
    l_firstDistrict NUMBER;

  BEGIN
    l_sq_handle_routes_code := sq_handle_routes.NEXTVAL;

    SELECT
      link_.districtCode
    INTO
      l_firstDistrict
    FROM
      sepo_fail2_routes data,
      sepo_cex_to_district link_
    WHERE
        data.id_fail2 = pkg_importRow.id
      AND
        data.number_ = 1
      AND
        data.cex = link_.cexCode;

    INSERT INTO handle_routes
    VALUES
    ( l_sq_handle_routes_code, l_firstDistrict, p_hashRoute);

    INSERT INTO routeItems
    SELECT
      sq_routeitems.NEXTVAL,
      l_sq_handle_routes_code,
      order_index,
      dist_code,
      producers,
      account_in_production
    FROM
      t_omroutes_route_items;

    RETURN l_sq_handle_routes_code;

  END;

  -- создание или получение уже существующего состава маршрута
  -- для хеширования состава маршрута используется базовый функционал Омеги
  -- Алгоритм:
  -- 1. получает состав маршрута из файла;
  -- 2. вычисляется хеш;
  -- 3. если хеш уже существует в базе, то возвращает
  -- код состава маршрута из БД;
  -- 4. иначе - создает новую запись и возвращает ее
  FUNCTION GetStructureRoute RETURN NUMBER
  IS
    l_hashRoute handle_routes.strcode%TYPE;
    l_sq_handle_routes_code NUMBER;

  BEGIN
    DELETE FROM t_omroutes_route_items;

    -- в временную таблицу помещаются элементы состава маршрута
    -- для того, что запустить базовый функционал хеширования.
    -- Если задан основной цех в файле импорта, то тип элемента
    -- состава - "изготовитель", иначе - "последующий пункт"
    INSERT INTO t_omroutes_route_items
    SELECT
      1,
      number_ - 1,
      link_.districtCode,
      CASE
        WHEN data.cex = pkg_importRow.ocex THEN 3
        ELSE
          4
      END,
      NULL
    FROM
      sepo_fail2_routes data,
      sepo_cex_to_district link_
    WHERE
        data.cex = link_.cexCode
      AND
        data.id_fail2 = pkg_importRow.id
      AND
        data.number_ !=
          (
          SELECT
            Max(number_)
          FROM
              sepo_fail2_routes data_
          WHERE
              data_.id_fail2 = data.id_fail2
          )
    ORDER BY
      data.id,
      data.number_;

    l_hashRoute := omroutes.EncodeRouteByItems(1);

    SELECT
      Max(code)
    INTO
      l_sq_handle_routes_code
    FROM
      handle_routes
    WHERE
        strCode = l_hashRoute;

    IF l_sq_handle_routes_code IS NOT NULL THEN
      RETURN l_sq_handle_routes_code;

    ELSE
      RETURN CreateStructureRoute(l_hashRoute);

    END IF;

  END;

  -- создание маршрута обработки
  -- возвращает код маршрута
  -- принимает код состава маршрута
  FUNCTION CreateWorkRoute(p_handle NUMBER) RETURN NUMBER
  IS
    l_routeWorkCode NUMBER;

  BEGIN
    SELECT
      Max(code)
    INTO
      l_routeWorkCode
    FROM
      routes
    WHERE
        detCode = pkg_importRow.docCode
      AND
        target = 3
      AND
        handle = p_handle;

    IF l_routeWorkCode IS NULL THEN
      SELECT routes_code.NEXTVAL INTO l_routeWorkCode FROM dual;

      INSERT INTO routes
      (
      code,detcode,dettype,type,recdate,
      notice,spccode,multiple,cntnum,cntdenom,
      collector,collprod,coll_acc_in_prod,target,appcode,
      confirmid,confirmed,confirmdate,ARCHIVE,archivedate,
      term,groupcode,handle,handle4ko,is_active,
      inckind,increason,increason_type,reason,enterprise,
      typical_route,performance,special,color,tspccode,
      tcntnum,tcntdenom,cparam,ordercode,orderitem,
      matcode,complexinc,startdate,changed_by_card,spcbillet,
      measure,inchandle
      )
      VALUES
      (
      l_routeWorkCode,pkg_importRow.docCode,pkg_importRow.docType,1,
      pkg_routeData.createDate,
      pkg_settings.notice,NULL,0,0,1,
      NULL,NULL,NULL,3,NULL,
      pkg_settings.userCode,0,pkg_routeData.modifyDate,0,NULL,
      NULL,NULL,p_handle,NULL,1,
      0,NULL,0,NULL,NULL,
      NULL,NULL,0,NULL,NULL,
      NULL,NULL,NULL,NULL,NULL,
      NULL,NULL,pkg_routeData.createDate,0,NULL,
      pkg_routeData.measCode,NULL
      );

      INSERT INTO routes_active_switch
      (
      code,routecode,ordernum,operation,
      operdate,userid,notice,notice_text
      )
      VALUES
      (sq_routes_active_switch.NEXTVAL,l_routeWorkCode,1,1,
      pkg_routeData.modifyDate,pkg_settings.userCode,1,pkg_settings.notice);

    ELSE
      UPDATE routes SET is_active = is_active + 1
      WHERE
          code = l_routeWorkCode;

    END IF;

    RETURN l_routeWorkCode;

  END;

  /* создание маршрута */
  PROCEDURE CreateRoute
  IS
    l_sq_handle_routes_code NUMBER;
    l_routeWorkCode NUMBER;
    l_endDistrict NUMBER;

    activeNumberRoute NUMBER;
    l_routeCode NUMBER;

  BEGIN
    -- получение состава маршрута

    l_sq_handle_routes_code := GetStructureRoute();
    -- форматирование дат
    pkg_routeData.createDate := Nvl(StringToDate(pkg_importRow.datv), SYSDATE);
    pkg_routeData.modifyDate := Nvl(StringToDate(pkg_importRow.datd),
      pkg_routeData.createDate);

    -- создание маршрута обработки.
    -- в случае, если на ДСЕ уже есть маршрут обработки с таким
    -- составом, то увеличивается количество ссылок на маршрут на 1

    l_routeWorkCode := CreateWorkRoute(l_sq_handle_routes_code);

    -- установка активности маршрута по приоритету из файла импорта
    IF pkg_importRow.prizm = 0 THEN
      activeNumberRoute := 1;
    ELSE
      activeNumberRoute := 0;
    END IF;

    -- получение последнего пункта маршрута
    SELECT
      link_.districtCode
    INTO
      l_endDistrict
    FROM
      sepo_fail2_routes data,
      sepo_cex_to_district link_
    WHERE
        data.id_fail2 = pkg_importRow.id
      AND
       data.cex = link_.cexCode
      AND
        data.number_ =
          (
          SELECT
            Max(number_)
          FROM
              sepo_fail2_routes data_
          WHERE
              data_.id_fail2 = data.id_fail2
          );

    /* создание маршрута */
    SELECT routes_code.NEXTVAL INTO l_routeCode FROM dual;

    INSERT INTO routes
    (
    code,detcode,dettype,type,recdate,
    notice,spccode,multiple,cntnum,cntdenom,
    collector,collprod,coll_acc_in_prod,target,appcode,
    confirmid,confirmed,confirmdate,ARCHIVE,archivedate,
    term,groupcode,handle,handle4ko,is_active,
    inckind,increason,increason_type,reason,enterprise,
    typical_route,performance,special,color,tspccode,
    tcntnum,tcntdenom,cparam,ordercode,orderitem,
    matcode,complexinc,startdate,changed_by_card,spcbillet,
    measure,inchandle
    )
    VALUES
    (
    l_routeCode,pkg_importRow.docCode,pkg_importRow.docType,1,
    pkg_routeData.createDate,
    pkg_settings.notice,pkg_importRow.spcCode,0,pkg_importRow.cntNum,pkg_importRow.cntDenom,
    l_endDistrict,NULL,NULL,0,NULL,
    pkg_settings.userCode,pkg_settings.routeStatus,pkg_routeData.modifyDate,0,NULL,
    NULL,NULL,l_sq_handle_routes_code,l_routeWorkCode,activeNumberRoute,
    0,NULL,0,NULL,NULL,
    NULL,NULL,0,NULL,NULL,
    NULL,NULL,NULL,NULL,NULL,
    NULL,NULL,pkg_routeData.createDate,0,NULL,
    pkg_routeData.measCode,NULL
    );

    INSERT INTO routes_active_switch
    (
    code,routecode,ordernum,operation,
    operdate,userid,notice,notice_text
    )
    VALUES
    (sq_routes_active_switch.NEXTVAL,l_routeCode,1,1,
    pkg_routeData.modifyDate,pkg_settings.userCode,1,pkg_settings.notice);

    p_sepo_import_fail2_log( pkg_importRow.id, 'Маршрут добавлен!');

  END;


END;
/