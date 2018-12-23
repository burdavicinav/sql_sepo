--SELECT * FROM pdpricetypes;

--DELETE FROM pdPriceTypes
--WHERE
--    code = 141;

--INSERT INTO pdPriceTypes
--SELECT

CREATE OR REPLACE PACKAGE pkg_sepo_prices
AS
  PD_TYPE_NOT_EXISTS_EXCEPTION EXCEPTION;
  PD_SOCODE_NOT_EXISTS_EXCEPTION EXCEPTION;
  PD_UNIT_NOT_EXISTS_EXCEPTION EXCEPTION;
  CURRENCY_NOT_EXISTS_EXCEPTION EXCEPTION;
  PRICE_NOT_VALID_EXCEPTION EXCEPTION;

  PROCEDURE AddPriceType(
    p_type pdPriceTypes.name%TYPE,
    p_sign pdPriceTypes.Sign%TYPE
    );

  PROCEDURE CreatePrice(
    p_type pdPricetypes.name%TYPE,
    p_soCode NUMBER,
    p_meas measures.shortName%TYPE,
    p_price NUMBER,
    p_cur_price currency.shortName%TYPE,
    p_date DATE
  );
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_prices
AS
  PROCEDURE AddPriceType(
    p_type pdPriceTypes.name%TYPE,
    p_sign pdPriceTypes.Sign%TYPE
    )
  IS
    l_cnt NUMBER;
  BEGIN
    SELECT Count(*) INTO l_cnt FROM pdPriceTypes WHERE name = p_type;

    IF l_cnt = 0 THEN
      INSERT INTO pdPriceTypes
      VALUES
      (sq_pdpricetypes.NEXTVAL, p_type, p_sign);

    END IF;

  END;

  PROCEDURE CorrectCreatePrice(
    p_type pdPricetypes.name%TYPE,
    p_soCode NUMBER,
    p_meas measures.shortName%TYPE,
    p_price NUMBER,
    p_cur_price currency.shortName%TYPE
  )
  IS
    l_cnt NUMBER;
  BEGIN
    SELECT Count(*) INTO l_cnt FROM pdPriceTypes WHERE name = p_type;

    IF l_cnt = 0 THEN RAISE PD_TYPE_NOT_EXISTS_EXCEPTION; END IF;

    SELECT Count(*) INTO l_cnt FROM stockobj WHERE code = p_soCode;

    IF l_cnt = 0 THEN RAISE PD_SOCODE_NOT_EXISTS_EXCEPTION; END IF;

    SELECT Count(*) INTO l_cnt FROM measures WHERE shortName = p_meas;

    IF l_cnt = 0 THEN RAISE PD_UNIT_NOT_EXISTS_EXCEPTION; END IF;

    SELECT Count(*) INTO l_cnt FROM currency WHERE shortName = p_cur_price;

    IF l_cnt = 0 THEN RAISE CURRENCY_NOT_EXISTS_EXCEPTION; END IF;

    IF p_price <= 0 THEN RAISE PRICE_NOT_VALID_EXCEPTION; END IF;

  END;

  PROCEDURE CreatePrice(
    p_type pdPricetypes.name%TYPE,
    p_soCode NUMBER,
    p_meas measures.shortName%TYPE,
    p_price NUMBER,
    p_cur_price currency.shortName%TYPE,
    p_date DATE
  )
  IS
    l_cnt NUMBER;

    l_pdType NUMBER;
    l_labelType NUMBER;
    l_unit NUMBER;
    l_user NUMBER;
    l_boCode NUMBER;
    l_currencyCode NUMBER;
    l_pdLabelCode NUMBER;
  BEGIN
    -- проверка на корректность загрузки цен
    CorrectCreatePrice(p_type, p_soCode, p_meas, p_price, p_cur_price);

    -- получение данных
    -- цена
    SELECT code INTO l_pdType FROM pdPriceTypes WHERE name = p_type;
    -- единица измерения
    SELECT code INTO l_unit FROM measures WHERE shortName = p_meas;
    -- текущий пользователь
    SELECT code INTO l_user FROM user_list WHERE loginName = USER;
    -- валюта
    SELECT currCode INTO l_currencyCode FROM currency WHERE shortName = p_cur_price;
    -- тип ценника
    SELECT code INTO l_labelType FROM pdLabeltypes WHERE name = 'Производство';

    -- проверка на существование цен у заданной позиции
    SELECT
      Count(*)
    INTO
      l_cnt
    FROM
      pdLabels
    WHERE
        TYPE = l_labelType
      AND
        articleCode = p_soCode;

    -- если цен нет, то создать метку
    IF l_cnt = 0 THEN
      SELECT sq_lva_pricedir.NEXTVAL INTO l_pdLabelCode FROM dual;

      INSERT INTO pdLabels
      (pdlabelcode, TYPE, articleCode, chapter, analog)
      VALUES
      (l_pdLabelCode, l_labelType, p_soCode, 0, 0);

    -- иначе получить ее код
    ELSE
      SELECT
        pdLabelCode
      INTO
        l_pdLabelCode
      FROM
        pdLabels
      WHERE
          TYPE = l_labelType
        AND
          articleCode = p_soCode;

    END IF;

    -- проверка на существование цены заданного типа
    SELECT
      Count(*)
    INTO
      l_cnt
    FROM
      pdPrices
    WHERE
        pdLabelCode = l_pdLabelCode
      AND
        TYPE = l_pdType;

    -- если цена заданного типа существует, то цена обновляется
    IF l_cnt > 0 THEN
      UPDATE pdPrices
      SET
        initDate = p_date,
        measCode = l_unit,
        userCode = l_user,
        userDate = SYSDATE,
        Value = p_price,
        currCode = l_currencyCode
      WHERE
          pdLabelCode = l_pdLabelCode
        AND
          TYPE = l_pdType;

    -- в противном случае, создается цена
    ELSE
      SELECT sq_business_objects_code.NEXTVAL INTO l_boCode FROM dual;

      INSERT INTO omp_objects
      (code, objType, num)
      VALUES
      (l_boCode, 1000014, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000014
      (soCode)
      VALUES
      (l_boCode);

      INSERT INTO pdPrices
      (pdPriceCode, TYPE, pdLabelCode, initDate, meascode, userDate,
        userCode, Value, currCode, soCode, status )
      VALUES
      (sq_lva_pricedir.NEXTVAL, l_pdType, l_pdLabelCode, p_date, l_unit, SYSDATE,
        l_user, p_price, l_currencyCode, l_boCode, 1);

    END IF;

  EXCEPTION
    WHEN PD_TYPE_NOT_EXISTS_EXCEPTION THEN
      Raise_Application_Error(-20103,
        'Неверно задан тип цены!');
    WHEN PD_SOCODE_NOT_EXISTS_EXCEPTION THEN
      Raise_Application_Error(-20104,
        'Заданной номенклатуры не существует!');
    WHEN PD_UNIT_NOT_EXISTS_EXCEPTION THEN
      Raise_Application_Error(-20105,
        'Заданной единицы измерения не существует!');
    WHEN CURRENCY_NOT_EXISTS_EXCEPTION THEN
      Raise_Application_Error(-20105,
        'Заданной валюты не существует!');
    WHEN PRICE_NOT_VALID_EXCEPTION THEN
      Raise_Application_Error(-20106,
        'Некорреткное значение цены!');
  END;

END;
/