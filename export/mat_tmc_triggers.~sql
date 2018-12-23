CREATE OR REPLACE TRIGGER taiur_sepo_export_materials
AFTER UPDATE OR INSERT ON materials
FOR EACH ROW

DECLARE
  l_create_user NUMBER;
  l_modify_user NUMBER;
BEGIN
  -- строчный триггер сохраняет данные об изменяемом материале
  -- определение пользователя, редактирующего запись
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- определение пользователя, создавшего запись
  IF :new.state = 0 THEN
    l_create_user := l_modify_user;

  ELSE
    SELECT
      userCode
    INTO
      l_create_user
    FROM
      xml_history
    WHERE
        xmlDocType = 1000001
      AND
        sql_type = 2
      AND
        ompCode = :new.code;

  END IF;

  -- сохранение данных
  INSERT INTO sepo_materials_temp
  VALUES
  (:new.soCode, :new.plCode, :new.measCode, :new.measCode2, :new.measCode3,
      :new.recDate, :new.updateDate, l_create_user, l_modify_user,
        :old.state, :new.state);

END;
/

CREATE OR REPLACE TRIGGER tai_sepo_export_materials
AFTER INSERT ON materials

DECLARE
  l_exists BOOLEAN;
BEGIN
  -- триггер использует сохраненные данные в строчном триггере
  -- и проверяет заводские коды всех новых материалов
  -- на уникальность
  FOR i IN (
    SELECT * FROM sepo_materials_temp
  ) LOOP
    l_exists := pkg_sepo_materials.CheckUniqueCode(i.plCode);

    IF NOT l_exists THEN
      Raise_Application_Error(-20110, 'Материал или ТМЦ с таким кодом уже существует!');
    END IF;

  END LOOP;

  -- очистить данные
  DELETE FROM sepo_materials_temp;

END;
/

CREATE OR REPLACE TRIGGER tau_sepo_export_materials
AFTER UPDATE ON materials

DECLARE
  l_exists BOOLEAN;
  l_export BOOLEAN;

  l_mat_data sepo_materials_temp%ROWTYPE;
  l_status NUMBER;
  l_prizn NUMBER;
BEGIN
  -- триггер использует сохраненные данные в строчном триггере
  -- и проверяет заводские коды всех изменяемых материалов
  -- на уникальность
  FOR i IN (
    SELECT * FROM sepo_materials_temp
  ) LOOP
    l_exists := pkg_sepo_materials.CheckUniqueCode(i.plCode);

    IF NOT l_exists THEN
      Raise_Application_Error(-20110, 'Материал или ТМЦ с таким кодом уже существует!');
    END IF;

  END LOOP;

  l_export := FALSE;
  pkg_sepo_export_materials.Clear();
  -- если все коды уникальны, то выполняется экспорт в dbf
  FOR i IN (
    SELECT * FROM sepo_materials_temp
  ) LOOP
    l_mat_data := i;

    -- срабатывает только на утверждение и аннулирование
    IF l_mat_data.state_new = 0
      OR
        l_mat_data.state_old = 2
          THEN
            CONTINUE;
    END IF;

    l_export := TRUE;
    -- статус материала
    l_status := NULL;
    IF l_mat_data.state_new = 1 THEN
      l_status := 0;
    ELSE
      l_status := 1;
    END IF;

    -- операция
    l_prizn := NULL;
    IF l_mat_data.state_old = 0 AND l_mat_data.state_new = 1 THEN
      l_prizn := 0;
    ELSIF l_mat_data.state_old = l_mat_data.state_new THEN
      l_prizn := 1;
    ELSIF l_mat_data.state_new = 2 THEN
      l_prizn := 2;
    END IF;

    pkg_sepo_export_materials.SelectMatRow(
      p_status => l_status,
      p_priznak => l_prizn,
      p_soCode => l_mat_data.soCode,
      p_plCode => l_mat_data.plCode,
      p_meas_1 => l_mat_data.unit_1,
      p_meas_2 => l_mat_data.unit_2,
      p_meas_3 => l_mat_data.unit_3,
      p_create_date => l_mat_data.createDate,
      p_modify_date => l_mat_data.modifyDate,
      p_create_user => l_mat_data.createUser,
      p_modify_user => l_mat_data.modifyUser
    );

  END LOOP;

  -- экспорт
  IF l_export THEN pkg_sepo_export_materials.Export(); END IF;

  -- очистка данных
  DELETE sepo_materials_temp;

END;
/

CREATE OR REPLACE TRIGGER taiur_sepo_export_tmc
AFTER INSERT OR UPDATE ON stock_other
FOR EACH ROW
DECLARE
  l_create_user NUMBER;
  l_modify_user NUMBER;
BEGIN
  -- строчный триггер сохраняет данные об изменяемом материале
  -- определение пользователя, редактирующего запись
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- определение пользователя, создавшего запись
  l_create_user := :new.recUser;

  -- сохранение данных
  INSERT INTO sepo_materials_temp
  VALUES
  (:new.code, :new.Sign, :new.measCode, NULL, NULL,
      :new.recDate, SYSDATE, l_create_user, l_modify_user,
        :old.is_annul, :new.is_annul);

END;
/

CREATE OR REPLACE TRIGGER taiu_sepo_export_tmc
AFTER INSERT OR UPDATE ON stock_other

DECLARE
  l_exists BOOLEAN;
  l_export BOOLEAN;

  l_state NUMBER;
  l_prizn NUMBER;
BEGIN
  -- триггер использует сохраненные данные в строчном триггере
  -- и проверяет заводские коды всех новых ТМЦ
  -- на уникальность
  FOR i IN (
    SELECT * FROM sepo_materials_temp
  ) LOOP
    l_exists := pkg_sepo_materials.CheckUniqueCode(i.plCode);

    IF NOT l_exists THEN
      Raise_Application_Error(-20110, 'Материал или ТМЦ с таким кодом уже существует!');
    END IF;

  END LOOP;

  -- если проверка на уникальность прощла успешно, то выполняется
  -- экспорт в dbf
  IF INSERTING THEN
    l_state := 0;
    l_prizn := 0;

  END IF;

  l_export := FALSE;
  pkg_sepo_export_materials.Clear();

  FOR i IN (
    SELECT * FROM sepo_materials_temp
  ) LOOP
    IF UPDATING THEN
      IF i.state_new = 0 AND i.state_old = 1
        OR
          i.state_new = i.state_old AND i.state_new = 1
        THEN CONTINUE;
      END IF;

      -- статус ТМЦ
      l_state := i.state_new;
      -- операция
      IF i.state_old = i.state_new AND i.state_new = 0 THEN
        l_prizn := 1;
      ELSIF i.state_old = 0 AND i.state_new = 1 THEN
        l_prizn := 2;
      END IF;

    END IF;

    l_export := TRUE;

    pkg_sepo_export_materials.SelectTmcRow(
      p_status => l_state,
      p_priznak => l_prizn,
      p_soCode => i.soCode,
      p_plCode => i.plCode,
      p_meas_1 => i.unit_1,
      p_create_date => i.createDate,
      p_modify_date => i.modifyDate,
      p_create_user => i.createUser,
      p_modify_user => i.modifyUser
      );
  END LOOP;

  IF l_export THEN pkg_sepo_export_materials.Export(); END IF;

  -- очистить данные
  DELETE FROM sepo_materials_temp;

END;
/