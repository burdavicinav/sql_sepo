CREATE OR R+

























































































































EPLACE TRIGGER tau_sepo_export_materials
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
    SELECT+ * FROM sepo_materials_temp
    ------
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

EXCEPTION
  WHEN pkg_sepo_export_materials.EXP_MAT_NOT_CORRECT_DM_EXCEPTION THEN
    Raise_Application_Error(
      -20110,
      'Поля "Диаметр" и "Количество жил" не могут быть заполнены одновременно!'
      );
  WHEN pkg_sepo_export_materials.EXP_MAT_NOT_CORRECT_TOL_EXCEPTION THEN
    Raise_Application_Error(
      -20110,
      'Поля "Толщина" и "Сечение" не могут быть заполнены одновременно!'
      );

END;
/