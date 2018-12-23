PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_import_global
CREATE OR REPLACE PACKAGE pkg_sepo_import_global
AS
  -- пакет предназначен для импорта различных данных в КИС "Омега"

  classify_not_founded EXCEPTION;

  -- справочник профессий
  PROCEDURE ClearProfessions;
  PROCEDURE LoadProfessions;

  -- справочник технологических операций
  PROCEDURE ClearOperCatalogs;
  PROCEDURE LoadOperCatalogs;
  PROCEDURE ClearOperations;
  PROCEDURE LoadOperations(p_opertype NUMBER);

  -- справочник технологических переходов
  PROCEDURE ClearSteps;
  PROCEDURE LoadSteps(p_is_load_classify_group NUMBER := 1);

  -- справочник моделей оборудования
  PROCEDURE ClearEqpModels(p_classify NUMBER);
  PROCEDURE LoadEqpModelCatalogs(p_classify NUMBER, p_owner NUMBER);
  PROCEDURE LoadEqpModels;

  -- узлы оснастки
  -- перед запуском отключить триггеры
  PROCEDURE LoadFixtureNodes(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER,
    p_type_default NUMBER DEFAULT NULL
    );

  -- оснастка
  -- перед запуском отключить триггеры
  PROCEDURE LoadFixture(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER,
    p_type_default NUMBER DEFAULT NULL
    );

  -- детали оснастки
  -- перед запуском отключить триггеры
  PROCEDURE LoadFixtureDetails(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
    );

  -- состав оснастки
  PROCEDURE LoadFixtureSpecifications (p_meascode NUMBER);

  PROCEDURE CreateDocument(p_data BLOB, p_doc NUMBER, p_name VARCHAR2, p_hash VARCHAR2);

  -- присоединенные файлы для оснастки
  PROCEDURE AttachFixtureDocuments;

  -- инструкции ТБ
  PROCEDURE LoadInstructionsTB(
    p_owner NUMBER,
    p_state NUMBER
  );

  PROCEDURE ClearStdFixtureData;

  PROCEDURE SetIdTableOnRecord;

  PROCEDURE GetStdSchemeName(
    p_table_descr VARCHAR2,
    p_scheme_name IN OUT VARCHAR2
  );

  PROCEDURE BuildStandardSchemes;

  -- ТП, удаление данных
  PROCEDURE ClearTpData;

  -- ТП, построение ссылок
  PROCEDURE UpdateTpLinks;

  -- парстнг формул стандартной оснастки
  PROCEDURE ParsingStdFixFormuls;

  -- настройка схем, атрибутов, перечислений стандартной оснастки
  PROCEDURE SetStdFixObjParams;

  -- настройка атрибутов для "старой" оснастки
  PROCEDURE SetOldFixObjParams;

  -- создание стандарта
  FUNCTION CreateGost (
    p_name VARCHAR2,
    p_state NUMBER,
    p_owner NUMBER,
    p_user NUMBER,
    p_date DATE := SYSDATE,
    p_gostcode NUMBER := NULL
  )
  RETURN NUMBER;

  -- импорт гостов стандартной оснастки
  PROCEDURE ImportStdGosts (
    p_owner NUMBER,
    p_state NUMBER
  );

  PROCEDURE LoadStdFixture(
    p_type_default NUMBER,
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
  );

  PROCEDURE CreateStdClassify (
    p_name VARCHAR2,
    p_owner NUMBER,
    p_level NUMBER
  );

  PROCEDURE LoadOldFixture (
    p_type_default NUMBER,
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
  );

  PROCEDURE CreateOldFixtureClassify (
    p_name VARCHAR2,
    p_owner NUMBER,
    p_level NUMBER
  );

  PROCEDURE DeleteStdFixture;

  FUNCTION TpImportValidate (p_tp NUMBER, p_tptype NUMBER) RETURN BOOLEAN;

  PROCEDURE ImportTp (
    p_groupcode NUMBER,
    p_letter NUMBER,
    p_state NUMBER,
    p_owner NUMBER
  );

  PROCEDURE SaveImportTpData;

  PROCEDURE ImportLog (p_msg VARCHAR2, p_type VARCHAR2 := 'INFO');

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_global
CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_global
AS
  TYPE string_list IS TABLE OF VARCHAR2(100);

  PROCEDURE DeleteLog (p_type NUMBER)
  AS
    pragma autonomous_transaction;
    begin
    DELETE FROM sepo_import_logs
    WHERE
        id_type = p_type;

    COMMIT;

  END;

  PROCEDURE Log_ (p_type NUMBER, p_base NUMBER, p_message VARCHAR2)
  AS
    pragma autonomous_transaction;
    begin
    INSERT INTO sepo_import_logs
    (id_type, id_base, log_)
    VALUES
    (p_type, p_base, p_message);

    COMMIT;

  END;

  -- получить код классификатора по его типу
  FUNCTION GetClassifyCode(p_clType NUMBER) RETURN NUMBER
  IS
    l_oper_classify NUMBER;
  BEGIN
    SELECT
      code
    INTO
      l_oper_classify
    FROM
      classify
    WHERE
        clType = p_clType;

    RETURN l_oper_classify;
  exception
    when no_data_found then
      raise classify_not_founded;
  END;

  -- получить код классификатора технологических операций
  FUNCTION GetOperClassifyCode RETURN NUMBER
  IS
  BEGIN
    RETURN GetClassifyCode(4);
  END;

  -- получить код классификатора технологических переходов
  FUNCTION GetStepClassifyCode RETURN NUMBER
  IS
  BEGIN
    RETURN GetClassifyCode(6);
  END;

  -- добавить группу в классификатор
  FUNCTION AddClassifyGroup (
    p_clcode number,
    p_grcode groups_in_classify.grcode%TYPE,
    p_grname groups_in_classify.grname%TYPE,
    p_grdescription groups_in_classify.grdescription%TYPE,
    p_parent groups_in_classify.upper_group%TYPE
  ) RETURN NUMBER
  IS
    l_classify_type NUMBER;
    l_soCode NUMBER;
    l_group NUMBER;
  BEGIN
    SELECT
      cltype
    INTO
      l_classify_type
    FROM
      classify
    WHERE
        code = p_clcode;

    l_classify_type := l_classify_type + 3000000;

    l_soCode := sq_business_objects_code.NEXTVAL;
    l_group := sq_groups_in_classify.NEXTVAL;

    INSERT INTO omp_objects
    (code, objType, num)
    VALUES
    (l_soCode, l_classify_type, so.GetNextSoNum() );

    execute immediate 'insert into obj_attr_values_' || l_classify_type || ' (socode) VALUES (:1)' using l_socode;

    INSERT INTO groups_in_classify
    (code, clCode, grCode, grName, grDescription, soCode, upper_group)
    VALUES
    (l_group, p_clcode, p_grcode, p_grname,
      p_grdescription, l_soCode, p_parent
      );

    RETURN l_group;
  END;

  -- заполнение классификатора операций
  PROCEDURE BuildOperClassify_pvt (
    p_classify NUMBER,
    p_parent NUMBER,
    p_omp_parent NUMBER
  )
  IS
    l_group NUMBER;
  BEGIN
    FOR i IN (
      SELECT
        f.f_owner,
        f.f_level,
        f.f_name,
        coalesce(c.f_code, '0') AS f_code
      FROM
        sepo_oper_folders f,
        sepo_oper_folder_codes c
      WHERE
          f.f_level = c.f_level(+)
        AND
          f.f_owner = p_parent
        AND
          EXISTS (
            SELECT 1 FROM sepo_oper_folders f_
            WHERE
                f_.f_owner = f.f_level
          )
    ) LOOP
      l_group := AddClassifyGroup(p_classify, i.f_code, i.f_name, i.f_level, p_omp_parent);
      BuildOperClassify_pvt(p_classify, i.f_level, l_group);
    END LOOP;

  END;

  -- заполнение классификатора переходов
  PROCEDURE BuildStepClassify_pvt (
    p_classify NUMBER,
    p_parent NUMBER,
    p_omp_parent NUMBER,
    p_is_step IN OUT NUMBER,
    p_path IN OUT VARCHAR2,
    p_step_path IN OUT VARCHAR2,
    p_level IN OUT NUMBER,
    p_order IN OUT NUMBER,
    p_is_load_classify_group NUMBER := 1
  )
  IS
    l_classify_code NUMBER;
    l_is_step NUMBER;
    l_path VARCHAR2(4000);
    l_step_path VARCHAR2(4000);

    l_object NUMBER;
    l_step_text technological_steps.steptext%TYPE;
    l_step_type NUMBER;
    l_group NUMBER;
    l_parent_step NUMBER;
  BEGIN
    -- получение кода классификатора
    l_classify_code := GetStepClassifyCode();

    -- цикл по каталогам/переходам
    FOR i IN (
      SELECT
        s.f_owner,
        s.f_level,
        s.f_name,
        t.id AS id_text,
        t.f_type,
        t.f_blob
      FROM
        sepo_tech_steps s
        left JOIN
        sepo_tech_step_texts t
        ON
            s.f_level = t.f_level
--          AND
--            t.f_type != 'OIT_Unknown'
      WHERE
          s.f_owner = p_parent
    ) LOOP

      IF p_is_load_classify_group = 0 AND Upper(i.f_name) LIKE 'ИЗ КЛАССИФИКАТОРА'
        OR p_is_step = 1 AND i.id_text IS NULL
          THEN CONTINUE;
      END IF;

      -- полный путь от каталога до перехода
      l_path := p_path;

      IF p_path IS NULL THEN
        p_path := i.f_name;
      ELSE
        p_path := p_path || ' ' || i.f_name;
      END IF;

      -- признак перехода
      l_is_step := p_is_step;
      IF i.id_text IS NOT NULL AND p_parent != 0 THEN p_is_step := 1; END IF;

      -- путь на переход
      l_step_path := p_step_path;

      IF p_is_step = 1 THEN
        IF p_step_path IS NULL THEN p_step_path := i.f_name;
        ELSE p_step_path := p_step_path || ' ' || i.f_name;
        END IF;

      END IF;

      -- загрузка каталогов/переходов
      -- если текущая строка - каталог, то создается группа
      -- иначе - переход
      IF p_is_step = 0 THEN
        l_object := AddClassifyGroup(
          l_classify_code,
          i.f_level,
          i.f_name,
          NULL,
          p_omp_parent
          );
      ELSE
        -- генерация нового кода
        l_object := sq_technological_steps.NEXTVAL;

        -- формирование текста перехода
        -- если он пустой, то передется полный путь для перехода
        IF i.f_blob IS NOT NULL THEN
          l_step_text := i.f_blob;
        ELSE
          l_step_text := p_step_path;
        END IF;

        -- определение типа перехода
        -- по умолчанию - "Нет"
        CASE
          WHEN i.f_type = 'OIT_Ust' THEN l_step_type := 1;
          WHEN i.f_type = 'OIT_Rab' THEN l_step_type := 2;
          WHEN i.f_type = 'OIT_Contr' THEN l_step_type := 3;
          ELSE l_step_type := NULL;
        END CASE;

        -- определение группы и родительского перехода
        l_group := NULL;
        l_parent_step := NULL;

        -- если родительский элемент - каталог, то переход входит в группу
        -- иначе - текущему переходу назначается родительский
        IF l_is_step = 0 THEN l_group := p_omp_parent;
        ELSE l_parent_step := p_omp_parent;
        END IF;

        -- создание перехода
        INSERT INTO technological_steps
        (code, name, steptype, steptext, groupcode, texttype, parent_step)
        VALUES
        (l_object, i.f_name, l_step_type, l_step_text, l_group, 0, l_parent_step);

      END IF;

      -- уровень рекурсии
      p_level := p_level + 1;
      -- номер по порядку
      p_order := p_order + 1;

      -- логирование
      INSERT INTO sepo_tech_steps_tree
      VALUES
      (i.f_owner, i.f_level, i.f_name, p_is_step, p_path, p_step_path, p_level, p_order, i.f_blob);

      -- рекурсия
      BuildStepClassify_pvt(
        p_classify,
        i.f_level,
        l_object,
        p_is_step,
        p_path,
        p_step_path,
        p_level,
        p_order,
        p_is_load_classify_group
      );

      -- значения на шаг назад
      p_is_step := l_is_step;
      p_level := p_level - 1;
      p_step_path := l_step_path;
      p_path := l_path;

    END LOOP;

  END;

  -- заполнение классификатора моделей оборудования
  PROCEDURE BuildModelsClassify_pvt (
    p_classify NUMBER,
    p_parent NUMBER,
    p_omp_parent NUMBER
  )
  IS
    l_code NUMBER;
    l_group NUMBER;
  BEGIN
    FOR i IN (
      SELECT * FROM sepo_eqp_model_folders f
      WHERE
          EXISTS (
            SELECT 1 FROM sepo_eqp_model_folders f_
            WHERE
                f.f_level = f_.f_owner
          )
        AND
          f_owner = p_parent
    ) LOOP
      IF i.f_owner = 0 THEN l_code := i.f_level; ELSE l_code := 0; END IF;

      l_group := AddClassifyGroup(p_classify, l_code, i.f_name, NULL, p_omp_parent);
      BuildModelsClassify_pvt(p_classify, i.f_level, l_group);

    END LOOP;

  END;

  -- установка суффикса техлогической операции
  PROCEDURE SetOperaionSuffix
  IS
  BEGIN
    -- уникальные операции
    UPDATE sepo_oper_recs SET suf_code = '00'
    WHERE
        id IN (
          SELECT
            id
          FROM
            sepo_oper_recs
          WHERE
              f1 IN (
                SELECT
                  f1
                FROM
                  sepo_oper_recs
                GROUP BY
                  f1
                HAVING
                  Count(DISTINCT f_level) = 1
              )
        );

    -- операции с одинаковыми номерами
    FOR i IN (
      SELECT
        id,
        f1,
        Row_Number() OVER (PARTITION BY f1 ORDER BY f_level * (-1)) AS ord
      FROM
        sepo_oper_recs
      WHERE
          f1 IN (
            SELECT
              f1
            FROM
              sepo_oper_recs
            GROUP BY
              f1
            HAVING
              Count(DISTINCT f_level) > 1
          )
    ) LOOP
      UPDATE sepo_oper_recs
      SET
        suf_code = CASE WHEN i.ord > 0 AND i.ord < 10 THEN '0' ELSE '' END
            || i.ord
      WHERE
          id = i.id;
    END LOOP;

  END;

  -- добавить профессии на технологическую операцию
  PROCEDURE AddProfessionsOnOpers
  IS
    l_boCode NUMBER;
    l_oper_perf NUMBER;
  BEGIN
    FOR i IN (
      SELECT
        omp_r.code AS oper_code,
        omp_p.code AS prof_code
      FROM
        sepo_oper_recs r,
        sepo_professions_on_opers o,
        sepo_professions p,
        technology_operations omp_r,
        professions omp_p
      WHERE
          o.id_oper = r.id
        AND
          p.id = o.id_prof
        AND
          omp_r.description = r.f_level * (-1)
        AND
          omp_p.profCode = p.prof_code
    ) LOOP
      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, num)
      VALUES
      (l_bocode, 1000034, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000034
      (socode)
      VALUES
      (l_bocode);

      l_oper_perf := sq_tpoper_performers.NEXTVAL;

      INSERT INTO oper_performers
      (code, oper_code, category, profession, socode)
      VALUES
      (l_oper_perf, i.oper_code, 1, i.prof_code, l_bocode);

    END LOOP;

  END;

  FUNCTION GetCurrentUser_pvt RETURN NUMBER
  IS
    l_user NUMBER;
  BEGIN
    SELECT code INTO l_user FROM user_list WHERE loginname = USER;
    RETURN l_user;
  END;

  PROCEDURE ClearProfessions
  IS
  BEGIN
    -- удаляет все профессии, которые не связаны с сотрудниками
    DELETE FROM professions p
    WHERE
        NOT EXISTS (
          SELECT 1 FROM labouring_list lb
          WHERE
              lb.profession = p.code
        );
  END;

  PROCEDURE LoadProfessions
  IS
  BEGIN
    -- добавляет профессии, если их нет в справочнике
    INSERT INTO professions
    (code, profcode, name, shortname)
    SELECT
      sq_profession.NEXTVAL,
      prof_code,
      prof_name,
      SubStr(prof_name, 1, 16) AS prof_short_name
    FROM
      sepo_professions pl
    WHERE
        NOT EXISTS (
          SELECT 1 FROM professions p
          WHERE
              p.profCode = pl.prof_code
        );
  END;

  PROCEDURE ClearOperCatalogs
  IS
    l_oper_classify NUMBER;
  BEGIN
    l_oper_classify := GetOperClassifyCode();

    DELETE FROM toperations_to_group;

    DELETE
    FROM
      groups_in_classify
    WHERE
        clCode = l_oper_classify;

    DELETE
    FROM
      omp_objects
    WHERE
      objType = 3000004;
  END;

  PROCEDURE LoadOperCatalogs
  IS
    l_oper_classify NUMBER;
  BEGIN
    l_oper_classify := GetOperClassifyCode();
    BuildOperClassify_pvt(l_oper_classify, 0, NULL);
  END;

  PROCEDURE ClearOperations
  IS
  BEGIN
    DELETE FROM technology_operations;
  END;

  PROCEDURE LoadOperations(p_opertype NUMBER)
  IS
  BEGIN
    SetOperaionSuffix();

    FOR i IN (
      SELECT
        op.*,
        coalesce(gr.code, gr_global.code) AS grCode
      FROM
        v_sepo_operations op,
        (SELECT * FROM groups_in_classify WHERE clCode = 4) gr,
        (SELECT * FROM groups_in_classify WHERE clCode = 4 AND grCode = '01') gr_global
      WHERE
          op.f_owner = gr.grDescription(+)
        AND
          op.f1 IS NOT NULL
    ) LOOP
      INSERT INTO technology_operations
      (code, opercode, variantcode, opertype, name, description)
      VALUES
      (sq_technology_operations.NEXTVAL, i.f1, i.suf_code, p_opertype, i.f_name, i.f_level);

      INSERT INTO toperations_to_group
      VALUES
      (sq_technology_operations.CURRVAL, i.grCode);

    END LOOP;

    AddProfessionsOnOpers();

  END;

  PROCEDURE ClearSteps
  IS
    l_classify_code NUMBER;
  BEGIN
    l_classify_code := GetStepClassifyCode();

    DELETE FROM technological_steps;

    DELETE
    FROM
      groups_in_classify
    WHERE
        clCode = l_classify_code;

    DELETE
    FROM
      omp_objects
    WHERE
      objType = 3000006;

  END;

  PROCEDURE LoadSteps(p_is_load_classify_group NUMBER := 1)
  IS
    l_classify NUMBER;
    l_is_step NUMBER;
    l_path VARCHAR2(4000);
    l_step_path VARCHAR2(4000);
    l_level NUMBER;
    l_order NUMBER;
  BEGIN
    DELETE FROM sepo_tech_steps_tree;

    l_classify := GetStepClassifyCode();
    l_is_step := 0;
    l_path := '';
    l_step_path := '';
    l_level := 0;
    l_order := 0;

    BuildStepClassify_pvt (
      l_classify,
      0,
      NULL,
      l_is_step,
      l_path,
      l_step_path,
      l_level,
      l_order,
      p_is_load_classify_group
      );

  END;

  PROCEDURE ClearEqpModels(p_classify NUMBER)
  IS
--    TYPE omp_array IS TABLE OF NUMBER;
--    l_array omp_array;
  BEGIN
    DELETE FROM groups_in_classify
    WHERE
        clcode = p_classify;

    DELETE FROM sepo_integer_table;

    INSERT INTO sepo_integer_table
    SELECT soCode FROM equipment_model;

--    SELECT socode BULK COLLECT INTO l_array FROM equipment_model;
    DELETE FROM equipment_model;

    DELETE FROM omp_objects
    WHERE
        code IN (SELECT numb FROM sepo_integer_table);

--    FOR i IN 1..l_array.Count() LOOP
--      DELETE FROM omp_objects WHERE code = l_array(i);
--    END LOOP;

--    FORALL i IN l_array.first..l_array.last
--    DELETE FROM omp_objects WHERE code = l_array(i);

  END;

  PROCEDURE LoadEqpModelCatalogs(p_classify NUMBER, p_owner NUMBER)
  IS
  BEGIN
    UPDATE classify SET owner = p_owner
    WHERE
        code = p_classify;

    BuildModelsClassify_pvt(p_classify, 0, NULL);
  END;

  PROCEDURE LoadEqpModels
  IS
    l_socode NUMBER;
    l_model NUMBER;
    l_user NUMBER;
    l_type CONSTANT NUMBER := 1000011;
  BEGIN
    l_user := GetCurrentUser_pvt();

    FOR i IN (
      SELECT
        f_name,
        f_level,
        Max(f1) AS f1,
        Max(f2) AS f2,
        Max(f3) AS f3,
        Max(f4) AS f4,
        Max(f5) AS f5,
        Max(f6) AS f6,
        Max(f7) AS f7,
        Max(f8) AS f8,
        Max(f9) AS f9,
        Max(f10) AS f10,
        Max(f11) AS f11
      FROM
        v_sepo_eqp_models_unique
      GROUP BY
        f_name,
        f_level
    ) LOOP
      l_socode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, num)
      VALUES
      (l_socode, l_type, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000011
      (soCode)
      VALUES
      (l_socode);

      pkg_sepo_attr_operations.Init(l_type);

      pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F1',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f1
      );

      pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F2',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f2
      );

      pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F3',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f3
      );

      pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F4',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f4
      );

      pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F5',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f5
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F6',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f6
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F7',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f7
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F8',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f8
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F9',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f9
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F10',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f10
      );

       pkg_sepo_attr_operations.AddAttrData (
        p_name => 'F11',
        p_type => pkg_sepo_attr_operations.ATTR_TYPE_STRING,
        p_value => i.f11
      );

      pkg_sepo_attr_operations.UpdateAttrs(l_socode);

      l_model := sq_equipment_model.NEXTVAL;

      INSERT INTO equipment_model
      (code, socode, recdate, text, Sign, ARCHIVE, creator)
      VALUES
      (l_model, l_socode, SYSDATE, i.f_name, i.f_level, 0, l_user);

    END LOOP;

  END;

  PROCEDURE LoadFixtureNodes(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER,
    p_type_default NUMBER DEFAULT NULL
    )
  IS
    l_date DATE := SYSDATE;
    l_prod_code NUMBER;
    l_bo_code NUMBER;
    l_ko_code NUMBER;
    l_prod_history NUMBER;
    l_prom_code NUMBER;
    l_so_code NUMBER;
    l_description stockobj.description%TYPE;
  BEGIN
    DeleteLog(1);

    -- инициализация атрибутов
    pkg_sepo_attr_operations.Init(31);

    pkg_sepo_attr_operations.addAttr('ART_ID');
    pkg_sepo_attr_operations.addAttr('SECTION_ID');
    pkg_sepo_attr_operations.addAttr('ORDER');
    pkg_sepo_attr_operations.addAttr('О_ВО');

    pkg_sepo_attr_operations.genInsertSql();

    -- запрос загрузки узлов оснастки
    FOR i IN (
      SELECT
        *
      FROM
        v_sepo_fixture_nodes_load
      WHERE
          NOT EXISTS (
            SELECT 1 FROM bo_production
            WHERE
                TYPE = 31
              AND
                Sign = designation
          )
    ) LOOP
      l_prod_code := sq_production.NEXTVAL;

      INSERT INTO bo_production
      (code, Sign, TYPE)
      VALUES
      (l_prod_code, i.designation, 31);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 1000090, NULL, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000090
      (socode)
      VALUES
      (l_bo_code);

      INSERT INTO okp_boproduction_params
      (prodcode, socode)
      VALUES
      (l_prod_code, l_bo_code);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 31, NULL, so.GetNextSoNum());

      pkg_sepo_attr_operations.setValue('ART_ID', i.art_id);
      pkg_sepo_attr_operations.setValue('SECTION_ID', i.section_id);
      pkg_sepo_attr_operations.setValue('ORDER', i.osn_type);
      pkg_sepo_attr_operations.setValue('О_ВО', i.o_vo);
      pkg_sepo_attr_operations.insertAttrs(l_bo_code);

      l_ko_code := sq_unvcode.NEXTVAL;

      INSERT INTO business_objects
      (code, TYPE, doccode, owner, checkout, name, revision, revsign,
        prodcode, access_level, today_state, today_statedate, today_stateuser,
          create_date, create_user
          )
      VALUES
      (l_bo_code, 31, l_ko_code, p_owner, NULL, i.designation, 0, NULL,
        l_prod_code, NULL, p_state, l_date, -2,
          l_date, -2);

      l_prod_history := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history
      (code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode)
      VALUES
      (l_prod_history, l_prod_code, 0, l_bo_code, l_date, NULL, 0,
        -2, NULL);

      UPDATE business_objects
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          prodcode = l_prod_code;

      UPDATE bo_production
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          code = l_prod_code;

      INSERT INTO konstrobj
      (unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
        kind, supplytype, owner, protection, recdate, meascode, revision,
          prodcode, formedfrom, formedtype)
      VALUES
      (l_ko_code, l_ko_code, 31, l_bo_code, 0, i.designation, i.name, NULL, 1,
        NULL, 0, p_owner, 0, l_date, p_meascode, 0,
          l_prod_code, NULL, NULL);

      INSERT INTO spclist
      (code, sign, name, notice, suppcode, owner, protection, recdate,
        spctype1, spctype2, kotype, format, stocknumber)
      VALUES
      (l_ko_code, i.designation, i.name, NULL, 0, p_owner, 0, l_date,
        0, 1, 31, NULL, i.doc_id);

      INSERT INTO fixture_base
      (code, kotype, fixture_types_code, originalname)
      VALUES
      (l_ko_code, 31, coalesce(i.id_type, p_type_default), i.designation);

      l_so_code := sq_stockobj.NEXTVAL;
      l_description := i.designation || ' ' || i.name;

      INSERT INTO stockobj
      (code, basetype, basecode, SUBTYPE, fk_bo_production, description,
        desc_date, desc_fmt, meascode, desc_update_check, is_annul,
          recdate, owner, notice, attr, Sign, name, unvcode,
            mat_state, socode)
      VALUES
      (l_so_code, 0, l_prod_code, 31, l_prod_code, l_description,
        l_date, NULL, p_meascode, 0, 0,
          l_date, p_owner, NULL, 1, i.designation, i.name, l_ko_code,
            NULL, l_so_code);

      l_prom_code := sq_businessobj_promotion_code.NEXTVAL;

      INSERT INTO businessobj_promotion
      (code, businessobj, operation, usercode, lastname, donedate, rdate,
        prev_state, current_state, note, statedate, todate, action,
          revision, iicode, mainpromcode)
      VALUES
      (l_prom_code, l_bo_code, NULL, -2, 'OMP Администратор', l_date, l_date,
        NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_prom_code);

      Log_ (1, i.id, 'OK');

    END LOOP;

  END;

  PROCEDURE LoadFixture(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER,
    p_type_default NUMBER DEFAULT NULL
    )
  IS
    l_date DATE := SYSDATE;
    l_prod_code NUMBER;
    l_bo_code NUMBER;
    l_ko_code NUMBER;
    l_prod_history NUMBER;
    l_prom_code NUMBER;
    l_so_code NUMBER;
    l_description stockobj.description%TYPE;
  BEGIN
    DeleteLog(2);

    -- инициализация атрибутов
    pkg_sepo_attr_operations.Init(32);

    pkg_sepo_attr_operations.addAttr('ART_ID');
    pkg_sepo_attr_operations.addAttr('SECTION_ID');
    pkg_sepo_attr_operations.addAttr('ORDER');
    pkg_sepo_attr_operations.addAttr('О_ВО');

    pkg_sepo_attr_operations.genInsertSql();

    -- запрос загрузки узлов оснастки
    FOR i IN (
      SELECT
        *
      FROM
        v_sepo_fixture_load
       WHERE
          NOT EXISTS (
            SELECT 1 FROM bo_production
            WHERE
                TYPE = 32
              AND
                Sign = designation
          )
    ) LOOP
      l_prod_code := sq_production.NEXTVAL;

      INSERT INTO bo_production
      (code, Sign, TYPE)
      VALUES
      (l_prod_code, i.designation, 32);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 1000090, NULL, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000090
      (socode)
      VALUES
      (l_bo_code);

      INSERT INTO okp_boproduction_params
      (prodcode, socode)
      VALUES
      (l_prod_code, l_bo_code);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 32, NULL, so.GetNextSoNum());

      pkg_sepo_attr_operations.setValue('ART_ID', i.art_id);
      pkg_sepo_attr_operations.setValue('SECTION_ID', i.section_id);
      pkg_sepo_attr_operations.setValue('ORDER', i.osn_type);
      pkg_sepo_attr_operations.setValue('О_ВО', i.o_vo);
      pkg_sepo_attr_operations.insertAttrs(l_bo_code);

      l_ko_code := sq_unvcode.NEXTVAL;

      INSERT INTO business_objects
      (code, TYPE, doccode, owner, checkout, name, revision, revsign,
        prodcode, access_level, today_state, today_statedate, today_stateuser,
          create_date, create_user
          )
      VALUES
      (l_bo_code, 32, l_ko_code, p_owner, NULL, i.designation, 0, NULL,
        l_prod_code, NULL, p_state, l_date, -2,
          l_date, -2);

      l_prod_history := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history
      (code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode)
      VALUES
      (l_prod_history, l_prod_code, 0, l_bo_code, l_date, NULL, 0,
        -2, NULL);

      UPDATE business_objects
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          prodcode = l_prod_code;

      UPDATE bo_production
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          code = l_prod_code;

      INSERT INTO konstrobj
      (unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
        kind, supplytype, owner, protection, recdate, meascode, revision,
          prodcode, formedfrom, formedtype)
      VALUES
      (l_ko_code, l_ko_code, 32, l_bo_code, 0, i.designation, i.name, NULL, -1,
        NULL, 0, p_owner, 0, l_date, p_meascode, 0,
          l_prod_code, NULL, NULL);

      INSERT INTO details
      (code, kotype, Sign, name, notice, suppcode, owner, protection,
        recdate, format, stocknumber)
      VALUES
      (l_ko_code, 32, i.designation, i.name, NULL, 0, p_owner, 0,
        l_date, NULL, i.doc_id);

      INSERT INTO fixture_base
      (code, kotype, fixture_types_code, originalname)
      VALUES
      (l_ko_code, 32, coalesce(i.id_type, p_type_default), i.designation);

      l_so_code := sq_stockobj.NEXTVAL;
      l_description := i.designation || ' ' || i.name;

      INSERT INTO stockobj
      (code, basetype, basecode, SUBTYPE, fk_bo_production, description,
        desc_date, desc_fmt, meascode, desc_update_check, is_annul,
          recdate, owner, notice, attr, Sign, name, unvcode,
            mat_state, socode)
      VALUES
      (l_so_code, 0, l_prod_code, 32, l_prod_code, l_description,
        l_date, NULL, p_meascode, 0, 0,
          l_date, p_owner, NULL, 1, i.designation, i.name, l_ko_code,
            NULL, l_so_code);

      l_prom_code := sq_businessobj_promotion_code.NEXTVAL;

      INSERT INTO businessobj_promotion
      (code, businessobj, operation, usercode, lastname, donedate, rdate,
        prev_state, current_state, note, statedate, todate, action,
          revision, iicode, mainpromcode)
      VALUES
      (l_prom_code, l_bo_code, NULL, -2, 'OMP Администратор', l_date, l_date,
        NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_prom_code);

      Log_ (2, i.id, 'OK');

    END LOOP;

  END;

  PROCEDURE LoadFixtureDetails(
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
    )
  IS
    l_date DATE := SYSDATE;
    l_prod_code NUMBER;
    l_bo_code NUMBER;
    l_ko_code NUMBER;
    l_prod_history NUMBER;
    l_prom_code NUMBER;
    l_so_code NUMBER;
    l_description stockobj.description%TYPE;
  BEGIN
    DeleteLog(3);

    -- инициализация атрибутов
    pkg_sepo_attr_operations.Init(2);

    pkg_sepo_attr_operations.addAttr('ART_ID');
    pkg_sepo_attr_operations.addAttr('SECTION_ID');
    pkg_sepo_attr_operations.genInsertSql();

    -- запрос загрузки узлов оснастки
    FOR i IN (
      SELECT
        l.*
      FROM
        v_sepo_fixture_details_load l
      WHERE
          (
          SELECT
            Count(*)
          FROM
            konstrobj
          WHERE
              itemtype = 2
            AND
              Sign = l.designation
        ) = 0

    ) LOOP
      l_prod_code := sq_production.NEXTVAL;

      INSERT INTO bo_production
      (code, Sign, TYPE)
      VALUES
      (l_prod_code, i.designation, 2);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 1000090, NULL, so.GetNextSoNum());

      INSERT INTO obj_attr_values_1000090
      (socode)
      VALUES
      (l_bo_code);

      INSERT INTO okp_boproduction_params
      (prodcode, socode)
      VALUES
      (l_prod_code, l_bo_code);

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, scheme, num)
      VALUES
      (l_bo_code, 2, NULL, so.GetNextSoNum());

      pkg_sepo_attr_operations.setValue('ART_ID', i.art_id);
      pkg_sepo_attr_operations.setValue('SECTION_ID', i.section_id);
      pkg_sepo_attr_operations.insertAttrs(l_bo_code);

      l_ko_code := sq_unvcode.NEXTVAL;

      INSERT INTO business_objects
      (code, TYPE, doccode, owner, checkout, name, revision, revsign,
        prodcode, access_level, today_state, today_statedate, today_stateuser,
          create_date, create_user
          )
      VALUES
      (l_bo_code, 2, l_ko_code, p_owner, NULL, i.designation, 0, NULL,
        l_prod_code, NULL, p_state, l_date, -2,
          l_date, -2);

      l_prod_history := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history
      (code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode)
      VALUES
      (l_prod_history, l_prod_code, 0, l_bo_code, l_date, NULL, 0,
        -2, NULL);

      UPDATE business_objects
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          prodcode = l_prod_code;

      UPDATE bo_production
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          code = l_prod_code;

      INSERT INTO konstrobj
      (unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
        kind, supplytype, owner, protection, recdate, meascode, revision,
          prodcode, formedfrom, formedtype)
      VALUES
      (l_ko_code, l_ko_code, 2, l_bo_code, 0, i.designation, i.name, NULL, -1,
        NULL, 0, p_owner, 0, l_date, p_meascode, 0,
          l_prod_code, NULL, NULL);

      INSERT INTO details
      (code, kotype, Sign, name, notice, suppcode, owner, protection,
        recdate, format, stocknumber)
      VALUES
      (l_ko_code, 2, i.designation, i.name, NULL, 0, p_owner, 0,
        l_date, NULL, i.doc_id);

      l_so_code := sq_stockobj.NEXTVAL;
      l_description := i.designation || ' ' || i.name;

      INSERT INTO stockobj
      (code, basetype, basecode, SUBTYPE, fk_bo_production, description,
        desc_date, desc_fmt, meascode, desc_update_check, is_annul,
          recdate, owner, notice, attr, Sign, name, unvcode,
            mat_state, socode)
      VALUES
      (l_so_code, 0, l_prod_code, 2, l_prod_code, l_description,
        l_date, NULL, p_meascode, 0, 0,
          l_date, p_owner, NULL, 1, i.designation, i.name, l_ko_code,
            NULL, l_so_code);

      l_prom_code := sq_businessobj_promotion_code.NEXTVAL;

      INSERT INTO businessobj_promotion
      (code, businessobj, operation, usercode, lastname, donedate, rdate,
        prev_state, current_state, note, statedate, todate, action,
          revision, iicode, mainpromcode)
      VALUES
      (l_prom_code, l_bo_code, NULL, -2, 'OMP Администратор', l_date, l_date,
        NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_prom_code);

      Log_ (3, i.id, 'OK');

    END LOOP;

  END;

  PROCEDURE LoadFixtureSpecifications(p_meascode NUMBER)
  IS
    l_bo_code NUMBER;
    l_spec_code NUMBER;
  BEGIN
    DeleteLog(4);

    FOR i IN (
      SELECT
        bo_sp.doccode AS spccode,
        bo.TYPE AS botype,
        CASE
          WHEN bo.type = 31 THEN 1
          ELSE 2
        END AS spc_section,
        bo.doccode AS code,
        sp.count_pc AS cnt,
        sp.position
      FROM
        sepo_osn_sostav sp,
        v_sepo_search_omega_link sl,
        business_objects bo_sp,
        v_sepo_search_omega_link l,
        business_objects bo
      WHERE
          sl.art_id = sp.proj_aid
        AND
          bo_sp.code = sl.bocode
        AND
          l.art_id = sp.part_aid
        AND
          bo.code = l.bocode
    ) LOOP
      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects
      (code, objtype, num)
      VALUES
      (l_bo_code, 2000031, so.getNextSoNum());

      INSERT INTO obj_attr_values_2000031
      (socode)
      VALUES
      (l_bo_code);

      l_spec_code := sq_specifications.NEXTVAL;

      INSERT INTO specifications
      (pkey, rowcode, usercode, spccode, code, SECTION, cntnum, cntdenom,
        meascode, position, ZONE, format, notice, sectcode, insertdate,
          advanced_name, num, point_of_view, corr_pkey, billet_for, copycode,
            addtype, sheetsign)
      VALUES
      (l_spec_code, l_bo_code, -2, i.spccode, i.code, i.botype, i.cnt, 1,
        p_meascode, i.position, NULL, NULL, NULL, i.spc_section, SYSDATE,
          NULL, NULL, NULL, NULL, NULL, NULL,
            NULL, NULL);

      Log_(4, NULL, 'OK!');

    END LOOP;

  END;

  PROCEDURE CreateDocument(p_data BLOB, p_doc NUMBER, p_name VARCHAR2, p_hash VARCHAR2)
  IS
    l_document NUMBER;
    l_user NUMBER;
    l_date DATE;
    l_count NUMBER;
  BEGIN
    l_date := SYSDATE;

    SELECT
      Count(*)
    INTO
      l_count
    FROM
      documents_params
    WHERE
        Lower(name) = Lower(p_name)
      AND
        Lower(HASH) = Lower(p_hash);

    IF l_count = 0 THEN
      l_document := sq_documents_code.NEXTVAL;

      INSERT INTO documents
      (code)
      VALUES
      (l_document);

      INSERT INTO documents_parts
      (code, num, data)
      VALUES
      (l_document, 1, p_data);

      INSERT INTO documents_params
      (code, name, filename, moddate, rdate, f_credate, f_moddate,
        HASH, hash_alg, verdate, usercode)
      VALUES
      (l_document, p_name, p_name, l_date, l_date, l_date, l_date,
        p_hash, 1, l_date, -2);

    ELSE
      SELECT
        Max(code)
      INTO
        l_document
      FROM
        documents_params
      WHERE
          Lower(name) = Lower(p_name)
        AND
          Lower(HASH) = Lower(p_hash);

    END IF;

    INSERT INTO sepo_osn_docs_link_omp
    VALUES
    (p_doc, l_document);
  END;

  PROCEDURE AttachFixtureDocuments
  IS
  BEGIN
    INSERT INTO attachments
    (code, businessobj, document, groupcode)
    SELECT
      sq_attachments_code.NEXTVAL,
      d.bocode,
      l.id_omega_doc,
      f.grcode
    FROM
      v_sepo_fixture_docs d,
      sepo_osn_docs_link_omp l,
      business_objects bo,
      sepo_attachment_groups_filter f
    WHERE
        d.doc_id = l.id_doc
      AND
        bo.code = d.bocode
      AND
        f.botype = bo.TYPE
      AND
        NOT EXISTS
        (
          SELECT 1 FROM attachments a
          WHERE
              a.businessobj = d.bocode
            AND
              a.document = l.id_omega_doc
        );
  END;

  PROCEDURE LoadInstructionsTB(
    p_owner NUMBER,
    p_state NUMBER
  )
  IS
    l_bocode NUMBER;
    l_socode NUMBER;
    l_instruction NUMBER;
    l_bo_history NUMBER;
    l_bo_prom NUMBER;
    l_date DATE;
    l_user NUMBER;
    l_username user_list.fullname%TYPE;
  BEGIN
    l_date := SYSDATE;

    SELECT
      code,
      fullname
    INTO
      l_user,
      l_username
    FROM
      user_list
    WHERE
        loginname = USER();

    FOR i IN (
      SELECT DISTINCT
        instruction
      FROM
        v_sepo_instructions_tb
      WHERE
          NOT EXISTS (
            SELECT 1 FROM instructions
            WHERE
                Sign = instruction
          )
    ) LOOP
      l_bocode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bocode, i.instruction, 267
      );

      l_socode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, num
      )
      VALUES (
        l_socode, 267, so.getNextSoNum()
      );

      INSERT INTO obj_attr_values_267
      (socode)
      VALUES
      (l_socode);

      l_instruction := sq_instructions.NEXTVAL;

      INSERT INTO instructions (
        code, Sign, name
      )
      VALUES (
        l_instruction, i.instruction, i.instruction
      );

      INSERT INTO business_objects (
        code, TYPE, doccode, owner, name, revision, prodcode
      )
      VALUES (
        l_socode, 267, l_instruction, p_owner, i.instruction, 0, l_bocode
      );

      l_bo_history := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, action, usercode
      )
      VALUES (
        l_bo_history, l_bocode, 0, l_socode, l_date, 0, l_user
      );

      l_bo_prom := sq_businessobj_promotion_code.NEXTVAL;

      INSERT INTO businessobj_promotion (
        code, businessobj, operation, usercode, lastname, donedate, rdate,
        current_state, statedate, action, mainpromcode
      )
      VALUES (
        l_bo_prom, l_socode, NULL, l_user, l_username, l_date, l_date,
        p_state, l_date, 0, l_bo_prom
      );

    END LOOP;

  END;

  FUNCTION GetStringWords(p_str VARCHAR2) RETURN string_list
  IS
    l_str_words string_list := string_list();
    l_pos NUMBER := 1;
    l_num NUMBER := 1;
    l_index NUMBER;
    l_str VARCHAR2(1000);
    l_sub_str VARCHAR2(100);

  BEGIN
    l_str := Trim(p_str);

    LOOP
      l_index := InStr(l_str, ' ', 1, l_num);

      IF l_index > 0 THEN
        l_sub_str := SubStr(l_str, l_pos, l_index - l_pos);
        l_str_words.extend();
        l_str_words(l_num) := l_sub_str;

        l_pos := l_index + 1;
        l_num := l_num + 1;

      ELSE
        l_sub_str := SubStr(l_str, l_pos, Length(l_str) - l_index);
        l_str_words.extend();
        l_str_words(l_num) := l_sub_str;

        EXIT;

      END IF;

    END LOOP;

    RETURN l_str_words;

  END;

  PROCEDURE GetStdSchemeName(
    p_table_descr VARCHAR2,
    p_scheme_name IN OUT VARCHAR2
  )
  IS
    l_catalog_words string_list;
    l_descr_words string_list;
    l_exists BOOLEAN;
  BEGIN
    l_catalog_words := getstringwords(p_scheme_name);
    l_descr_words := getstringwords(p_table_descr);

    FOR i IN 1..l_descr_words.Count() LOOP
      l_exists := FALSE;

      FOR j IN 1..l_catalog_words.Count() LOOP
        IF regexp_replace(l_catalog_words(j), '\W', '') =
          regexp_replace(l_descr_words(i), '\W', '') THEN
          l_exists := TRUE;
          EXIT;

        END IF;

      END LOOP;

      IF NOT l_exists THEN
        p_scheme_name := p_scheme_name || ' ' || l_descr_words(i);
      END IF;

    END LOOP;

  END;

  PROCEDURE BuildStandardSchemes
  IS
  BEGIN
    DELETE FROM sepo_std_schemes_temp;
    DELETE FROM sepo_std_schemes;

    FOR i IN (
      SELECT
        id,
        h_key,
        h_level,
        f_table,
        f_name,
        tbl_descr,
        scheme
      FROM
        v_sepo_std_schemes_build
    ) LOOP
      pkg_sepo_import_global.getstdschemename(i.tbl_descr, i.scheme);

      INSERT INTO sepo_std_schemes_temp (
        id_record, f_key, f_level, scheme_name, omp_name, tname
      )
      VALUES (
        i.id, i.h_key, i.h_level, i.scheme, SubStr(i.scheme, 1, 99), i.f_table
      );

    END LOOP;

    UPDATE sepo_std_schemes_temp
    SET omp_name =
      SubStr(
        omp_name,
        1,
        99 - (Length(To_Number(regexp_replace(tname, '\D', ''))) + 2)
        ) || '-T' || To_Number(regexp_replace(tname, '\D', ''))
    WHERE
      omp_name IN
        (
        SELECT
          omp_name
        FROM
          sepo_std_schemes_temp
        GROUP BY
          omp_name
        HAVING
          Count(DISTINCT id_record) > 1
        );

    INSERT INTO sepo_std_schemes (
      id_record, f_key, f_level, scheme_name, omp_name, tname, istable
    )
    SELECT
      id_record,
      f_key,
      f_level,
      scheme_name,
      omp_name,
      tname,
      0
    FROM
      sepo_std_schemes_temp;

  END;

  PROCEDURE ClearStdFixtureData
  IS
  BEGIN
    DELETE FROM sepo_std_attrs;
    DELETE FROM sepo_std_formulas;
    DELETE FROM sepo_std_tp_params;
    DELETE FROM sepo_std_record_contents;
    DELETE FROM sepo_std_schemes;
    DELETE FROM sepo_std_records;
    DELETE FROM sepo_std_fields;
    DELETE FROM sepo_std_folders;
    DELETE FROM sepo_std_table_rec_contents;
    DELETE FROM sepo_std_table_records;
    DELETE FROM sepo_std_table_fields;
    DELETE FROM sepo_std_tables;
    DELETE FROM sepo_std_enum_folders;
    DELETE FROM sepo_std_enum_contents;
    DELETE FROM sepo_std_enum_list;
  END;

  PROCEDURE SetIdTableOnRecord
  IS
  BEGIN
    UPDATE sepo_std_records r SET id_table = (
      SELECT
        t.id
      FROM
        sepo_std_record_contents c,
        sepo_std_fields f,
        sepo_std_tables t
      WHERE
          c.id_record = r.id
        AND
          c.id_field = f.id
        AND
          f.field = 'F16'
        AND
          t.f_table = c.field_value
    );
  END;

  PROCEDURE ClearTpData
  IS
  BEGIN
    DELETE FROM sepo_tp_tool_fields;
    DELETE FROM sepo_tp_tools;
    DELETE FROM sepo_tp_equipment_fields;
    DELETE FROM sepo_tp_equipments;
    DELETE FROM sepo_tp_worker_fields;
    DELETE FROM sepo_tp_workers;
    DELETE FROM sepo_tp_step_comments;
    DELETE FROM sepo_tp_step_fields;
    DELETE FROM sepo_tp_comments;
    DELETE FROM sepo_tp_steps;
    DELETE FROM sepo_tp_to_dce;
    DELETE FROM sepo_tp_oper_comments;
    DELETE FROM sepo_tp_oper_fields;
    DELETE FROM sepo_tp_opers;
    DELETE FROM sepo_tp_fields;
    DELETE FROM sepo_tech_processes;
    DELETE FROM sepo_tp_entities_legend;
    DELETE FROM sepo_tp_entities;
  END;

  PROCEDURE UpdateTpLinks
  IS
  BEGIN
    UPDATE sepo_tp_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_comments a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_oper_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_oper_comments a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_steps a SET id_op = (
      SELECT b.id FROM sepo_tp_opers b
      WHERE
          b.key_ = a.operkey
    );

    UPDATE sepo_tp_step_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_step_comments a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_workers a SET id_op = (
      SELECT b.id FROM sepo_tp_opers b
      WHERE
          b.key_ = a.operkey
    );

    UPDATE sepo_tp_workers a SET id_step = (
      SELECT b.id FROM sepo_tp_steps b
      WHERE
          b.key_ = a.perehkey
    );

    UPDATE sepo_tp_worker_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_equipments a SET id_op = (
      SELECT b.id FROM sepo_tp_opers b
      WHERE
          b.key_ = a.operkey
    );

    UPDATE sepo_tp_equipments a SET id_step = (
      SELECT b.id FROM sepo_tp_steps b
      WHERE
          b.key_ = a.perehkey
    );

    UPDATE sepo_tp_equipment_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

    UPDATE sepo_tp_tools a SET id_op = (
      SELECT b.id FROM sepo_tp_opers b
      WHERE
          b.key_ = a.operkey
    );

    UPDATE sepo_tp_tools a SET id_step = (
      SELECT b.id FROM sepo_tp_steps b
      WHERE
          b.key_ = a.perehkey
    );

    UPDATE sepo_tp_tool_fields a SET id_field = (
      SELECT b.id FROM sepo_tp_entities b
      WHERE
          b.f_code = a.field_name
    );

  END;

  PROCEDURE ImportLog (p_msg VARCHAR2, p_type VARCHAR2 := 'INFO')
  AS
    pragma autonomous_transaction;
    begin
    INSERT INTO sepo_import_log
    (msg, msg_type)
    VALUES
    (p_msg, p_type);

    COMMIT;

  END;

  FUNCTION ParseExpression(
    p_record NUMBER,
    p_reckey NUMBER,
    p_tblkey NUMBER,
    p_rule NUMBER,
    p_cntparams IN OUT NUMBER,
    p_parent_rule NUMBER := NULL
    )
  RETURN VARCHAR2
  IS
    l_str VARCHAR2(1000);
    l_value VARCHAR2(1000);
  BEGIN
    FOR i IN (
      SELECT
        id_record,
        id_rule,
        REPLACE(rule, '~', ' ') AS rule,
        id_field,
        field_mode,
        field_name,
        REPLACE(field_value, '~', ' ') AS field_value,
        ROWNUM AS num
      FROM
        sepo_std_expressions_temp
      WHERE
          id_record = p_record
        AND
          id_rule = p_rule
    ) LOOP
      IF i.num = 1 THEN l_str := i.rule; END IF;

      IF i.field_mode = 'IEM_EXPRESSION' THEN
        l_value := ParseExpression(
          p_record,
          p_reckey,
          p_tblkey,
          i.id_field,
          p_cntparams,
          p_rule
          );
      ELSE
        l_value := i.field_value;
      END IF;

      l_str := regexp_replace(
        l_str,
        '\{(.)?\[?' || i.field_name || '\]?\}',
        '\1' || l_value
        );

      IF i.id_field IS NULL AND i.field_name IS NOT NULL THEN
        p_cntparams := p_cntparams + 1;

--        INSERT INTO sepo_std_tp_params_temp (
--          reckey, tblkey, param
--        )
--        VALUES (
--          p_reckey, p_tblkey, i.field_name
--        );

        INSERT INTO sepo_std_tp_params (
          id_record, id_field, param
        )
        VALUES (
          p_record, Nvl(p_parent_rule, p_rule), i.field_name
        );

      END IF;

    END LOOP;

    RETURN l_str;

  END;

  PROCEDURE ApplyTpParamsOnFormuls
  IS
    l_tprule VARCHAR2(1000);
    l_next_op NUMBER;

    TYPE param_type IS RECORD (
      id NUMBER,
      param VARCHAR2(50),
      param_value VARCHAR2(50)
    );

    TYPE param_list IS TABLE OF param_type;
    l_pl param_list;
  BEGIN
    DELETE FROM sepo_std_tp_params_temp;

    INSERT INTO sepo_std_tp_params_temp (
      id_record, id_field, id_tool, param, value_
    )
    SELECT
      p.id_record,
      p.id_field,
      t.id,
      p.param,
      f.f_value
    FROM
      sepo_std_tp_params p
      JOIN
      sepo_std_table_records r
      ON
          r.id = p.id_record
      JOIN
      sepo_std_records pr
      ON
          pr.id_table = r.id_table
      left JOIN
      v_sepo_tp_tools t
      ON
          t.reckey = pr.f_key
        AND
          t.tblkey = r.f_key
      left JOIN
      sepo_tp_tool_fields f
      ON
          f.id_tool = t.id
        AND
          f.field_name = regexp_replace(p.param, '\[|\]', '');

    INSERT INTO sepo_std_formulas (
      id_record, id_field, field_value
    )
    SELECT
      id_record, id_field, field_value
    FROM
      sepo_std_formulas_temp
    WHERE
        cnt_tpparams = 0;

    --
    FOR i IN (
      SELECT
        fm.id_record,
        fm.id_field,
        fm.field_value AS rule
      FROM
        sepo_std_formulas_temp fm
      WHERE
          cnt_tpparams > 0
    ) LOOP
      SELECT
        id_tool,
        param,
        value_
      BULK COLLECT INTO
        l_pl
      FROM
        sepo_std_tp_params_temp
      WHERE
          id_record = i.id_record
        AND
          id_field = i.id_field
      ORDER BY
        id_tool;

      l_tprule := i.rule;

      FOR j IN 1..l_pl.Count LOOP

        l_tprule := REPLACE(
          l_tprule,
          l_pl(j).param,
          l_pl(j).param_value
        );

        IF j+1 > l_pl.Count THEN
          l_next_op := -1;
        ELSE
          l_next_op := Nvl(l_pl(j+1).id, 0);
        END IF;

        IF Nvl(l_pl(j).id, 0) != l_next_op THEN
          INSERT INTO sepo_std_formulas (
            id_record, id_field, id_tool, field_value
          )
          VALUES (
            i.id_record, i.id_field, l_pl(j).id, l_tprule
          );

          l_tprule := i.rule;

        END IF;

      END LOOP;

    END LOOP;

    DELETE FROM sepo_std_tp_params_temp;

  END;

  PROCEDURE ParsingStdFixFormuls
  IS
    l_cntparams NUMBER;
    l_rule VARCHAR2(1000);
  BEGIN
    DELETE FROM sepo_std_expressions_temp;
    DELETE FROM sepo_std_formulas_temp;

    DELETE FROM sepo_std_formulas;
    DELETE FROM sepo_std_tp_params;

    INSERT INTO sepo_std_expressions_temp (
      id_record, id_rule, rule, id_field, field_name, field_mode, field_value
    )
    SELECT
      id_record,
      id_field_rule,
      rule,
      id_field,
      field,
      field_mode,
      CASE
        WHEN field_mode = 'IEM_ASPARENT' THEN coalesce(field_value, p_field_value)
        ELSE field_value
      END
    FROM
      v_sepo_std_expressions;

    FOR i IN (
      SELECT
        r.id AS id_record,
        f.id AS id_field,
        pr.f_key AS reckey,
        r.f_key AS tblkey
      FROM
        sepo_std_table_records r,
        sepo_std_table_fields f,
        sepo_std_records pr
      WHERE
          r.id_table = f.id_table
        AND
          r.id_table = pr.id_table
        AND
          f.f_entermode = 'IEM_EXPRESSION'
--        AND
--          r.id = 634772
--        AND
--          f.id = 197326

    ) LOOP

      l_cntparams := 0;
      l_rule := ParseExpression(
        i.id_record,
        i.reckey,
        i.tblkey,
        i.id_field,
        l_cntparams
        );

--      Dbms_Output.put_line(l_cntparams);

      INSERT INTO sepo_std_formulas_temp (
        id_record, id_field, field_value, cnt_tpparams
      )
      VALUES (
        i.id_record, i.id_field, l_rule, l_cntparams
      );

--      ParseLog(i.id_record);


    END LOOP;

    ApplyTpParamsOnFormuls();

    DELETE FROM sepo_std_formulas_temp;
    DELETE FROM sepo_std_expressions_temp;

  END;

  FUNCTION CreateStdFixEnumeration (p_enum VARCHAR2)
  RETURN NUMBER
  IS
    l_enum_id NUMBER;
  BEGIN
    ImportLog('Создание перечисления: ' || p_enum);
    -- проверка на наличие перечисления
    SELECT
      Max(code)
    INTO
      l_enum_id
    FROM
      obj_enumerations
    WHERE
        name = p_enum;

    -- если перечисление не найдено, то оно создается
    IF l_enum_id IS NULL THEN
      l_enum_id := pkg_sepo_system_objects.createenumeration(p_enum);

    END IF;

    RETURN l_enum_id;

  END;

  PROCEDURE LoadStdFixEnumerations
  IS
    l_std_enum_id NUMBER;
  BEGIN
    ImportLog('Создание перечислений для стандартной оснастки');

    FOR i IN (
      SELECT
        id AS id_list,
        f_key,
        f_name
      FROM
        sepo_std_enum_list l
    ) LOOP
      SELECT
        Max(code)
      INTO
        l_std_enum_id
      FROM
        obj_enumerations
      WHERE
          name = i.f_name;

      IF l_std_enum_id IS NULL THEN
        l_std_enum_id := pkg_sepo_system_objects.createenumeration(i.f_name);

      END IF;

      INSERT INTO obj_enumerations_values (
        code, usercode, shortname, encode
      )
      SELECT
        sq_obj_enumerations_values.NEXTVAL,
        0,
        f_str,
        l_std_enum_id
      FROM
        (
        SELECT
          c.f_str
        FROM
          sepo_std_enum_contents c
        WHERE
            c.id_enum = i.id_list
          AND
            c.f_str IS NOT NULL
          AND
            NOT EXISTS (
              SELECT
                1
              FROM
                obj_enumerations_values v
              WHERE
                  v.encode = l_std_enum_id
                AND
                  v.shortname = c.f_str
            )
        GROUP BY
          c.f_str
        );

    END LOOP;

  END;

  FUNCTION CreateFixAttr(
    p_objtype NUMBER,
    p_attr_name VARCHAR2,
    p_attr_shortname VARCHAR2,
    p_attr_type NUMBER,
    p_enum NUMBER
  )
  RETURN NUMBER
  IS
    l_attr_id NUMBER;
    l_attr_type NUMBER;
    l_attr_enum_id NUMBER;
  BEGIN
--    Dbms_Output.put_line(p_attr_name);
    ImportLog('Создание атрибута: ' || p_attr_name);

    -- проверка на наличие атрибута с заданным перечислением
    SELECT
      Max(o.code),
      Max(o.attr_type),
      Max(i.encode)
    INTO
      l_attr_id,
      l_attr_type,
      l_attr_enum_id
    FROM
      obj_attributes o,
      obj_enum_info i
    WHERE
        o.code = i.code(+)
      AND
        o.objtype = p_objtype
      AND
        o.name = p_attr_name;

    -- если атрибута нет, то он создается
    -- если атрибут существует, но его тсруктура некорректна, то
    -- к наименованию текущего атрибута добавляется суффикс "old"
    -- далее создается новый атрибут
    IF l_attr_id IS NULL THEN
      l_attr_id := pkg_sepo_system_objects.createattr(
        p_objtype,
        p_attr_type,
        p_attr_shortname,
        p_attr_name,
        p_enum
      );

    ELSE
      IF l_attr_type != p_attr_type OR
        Nvl(l_attr_enum_id, 0) != Nvl(p_enum, 0) THEN

        UPDATE obj_attributes
        SET
          shortname = shortname || '#',
          name = name || '#'
        WHERE
            code = l_attr_id;

        l_attr_id := pkg_sepo_system_objects.createattr(
          p_objtype,
          p_attr_type,
          p_attr_shortname,
          p_attr_name,
          p_enum
        );

      END IF;

    END IF;

    RETURN l_attr_id;

  END;

  FUNCTION CreateStdFixGroup (p_group VARCHAR2)
  RETURN NUMBER
  IS
    l_group_id NUMBER;
  BEGIN
    ImportLog('Создание группы: ' || p_group);

    SELECT
      Max(code)
    INTO
      l_group_id
    FROM
      obj_types_groups
    WHERE
        objtype = 33
      AND
        name = p_group;

    IF l_group_id IS NULL THEN
      l_group_id := pkg_sepo_system_objects.creategroup(
        pkg_sepo_system_objects.std_fixture,
        p_group
      );

    END IF;

    RETURN l_group_id;

  END;

  PROCEDURE CreateStdAttrView
  IS
    l_sql VARCHAR2(1000);
    l_table NUMBER;
    l_reckey NUMBER;
    l_tblkey NUMBER;
    l_vo NUMBER;
  BEGIN
    ImportLog('Создание представления для атрибутов стпнд. оснастки');

    l_table := pkg_sepo_attr_operations.getcode(33, 'Table');
    l_reckey := pkg_sepo_attr_operations.getcode(33, 'RecKey');
    l_tblkey := pkg_sepo_attr_operations.getcode(33, 'TBLKey');
    l_vo := pkg_sepo_attr_operations.getcode(33, 'О_ВО');

    l_sql := 'create or replace view v_sepo_std_tech_attrs as ' ||
      'select t_33.socode,' ||
      't_33.a_' || l_table || ' as table_,' ||
      't_33.a_' || l_reckey || ' as reckey,' ||
      't_33.a_' || l_tblkey || ' as tblkey,' ||
      't_33.a_' || l_vo || ' as sign_vo' ||
      ' from business_objects b, obj_attr_values_33 t_33' ||
      ' where t_33.socode = b.code';

    EXECUTE IMMEDIATE l_sql;

  END;

  PROCEDURE SetStdFixObjParams
  IS
    l_rel_enum_id NUMBER;
    l_rel_enum_name obj_enumerations.name%TYPE;
    l_std_enum_id NUMBER;

    l_rel_attr_id NUMBER;
    l_rel_attr_name obj_attributes.shortname%TYPE;
    l_group_id NUMBER;
    l_group_name obj_types_groups.name%TYPE;
    l_scheme_id NUMBER;
    l_scheme_name obj_types_schemes.name%TYPE;
    l_def_scheme_id NUMBER;

    l_attr_id NUMBER;
    l_attr_type NUMBER;
    l_attr_enum_id NUMBER;

    l_foxpro_group VARCHAR2(10);
    l_foxpro_group_id NUMBER;
    l_foxpro_attr NUMBER;
    l_tp_group VARCHAR2(10);
    l_tp_group_id NUMBER;

  BEGIN
    DELETE FROM sepo_std_foxpro_attrs_temp;
    DELETE FROM sepo_std_attrs;

    l_foxpro_group := 'FoxPro';
    l_tp_group := 'ТП';

    -- выбор настроек
    SELECT
      enum_relative,
      attr_relative,
      group_name,
      default_scheme
    INTO
      l_rel_enum_name,
      l_rel_attr_name,
      l_group_name,
      l_scheme_name
    FROM
      sepo_std_import_settings;

    -- создание группы FoxPro
    l_foxpro_group_id := createstdfixgroup(l_foxpro_group);

    -- создание группы ТП
    l_tp_group_id := createstdfixgroup(l_tp_group);

    -- импорт перечислений
    loadstdfixenumerations();

    -- создание условного перечисления
    l_rel_enum_id := createstdfixenumeration(l_rel_enum_name);

    -- создание условного атрибута
    l_rel_attr_id := createfixattr(
      33,
      l_rel_attr_name,
      l_rel_attr_name,
      10,
      l_rel_enum_id
      );

    -- создание группы "Стандартная"
    l_group_id := createstdfixgroup(l_group_name);

    -- схема по умолчанию
    l_scheme_id := pkg_sepo_system_objects.createdefaultscheme(
      pkg_sepo_system_objects.std_fixture,
      l_scheme_name
    );

    l_def_scheme_id := l_scheme_id;

    -- удаление содержимого схемы по умолчанию
    pkg_sepo_system_objects.deletegroupsfromscheme(l_scheme_id);

    -- добавление атрибута в схему по умолчанию
    pkg_sepo_system_objects.addattrtoscheme(
      l_scheme_id,
      l_group_id,
      l_rel_attr_id
    );

    -- загрузка атрибутов
    -- если атрибут существует в системе, но его тип не совпадает,
    -- то атрибут пересоздается

    -- 1 класс атрибутов, основные атрибуты

    -- Table
    l_attr_id := createfixattr(33, 'Table', 'Table', 1, NULL);
    -- RecKey
    l_attr_id := createfixattr(33, 'RecKey', 'RecKey', 3, NULL);
    -- TBLKey
    l_attr_id := createfixattr(33, 'TBLKey', 'TBLKey', 3, NULL);
    -- О_ВО
    l_attr_id := createfixattr(33, 'О_ВО', 'О_ВО', 1, NULL);

    -- 2 класс атрибутов, атрибуты foxpro

    -- создание атрибутов foxpro
    FOR i IN (
      SELECT * FROM sepo_std_foxpro_attrs
    ) LOOP
      l_foxpro_attr := createfixattr(
        33,
        i.name,
        i.shortname,
        i.type_,
        NULL
      );

      INSERT INTO sepo_std_foxpro_attrs_temp(attrcode) VALUES (l_foxpro_attr);

    END LOOP;

    -- добавеление атрибутов foxpro в схему по умолчанию
    FOR j IN (
      SELECT
        attrcode
      FROM
        sepo_std_foxpro_attrs_temp
     ) LOOP
      pkg_sepo_system_objects.addattrtoscheme(
        l_def_scheme_id,
        l_foxpro_group_id,
        j.attrcode
      );

    END LOOP;

    -- 3 класс атрибутов, атрибуты-поля

    FOR i IN (
      SELECT
        omp_name AS omp_name,
        omp_type,
        id_omp_enum
      FROM
        v_sepo_std_attrs a
      GROUP BY
        omp_name,
        omp_type,
        id_omp_enum

    ) LOOP
      l_attr_id := createfixattr(
        33,
        i.omp_name,
        NULL,
        i.omp_type,
        i.id_omp_enum
        );

    END LOOP;

    -- связь атрибутов
    INSERT INTO sepo_std_attrs (
      id_table, id_attr, omp_attr, omp_enum
    )
    SELECT
      a.id_table,
      a.id_attr,
      o.code AS attr_code,
      a.id_enum
    FROM
      v_sepo_std_attrs a
      JOIN
      obj_attributes o
      ON
          o.objtype = 33
        AND
          a.omp_name = o.name;

    -- создание схем

    -- заполнение перечисления для схем
    INSERT INTO obj_enumerations_values (
      code, usercode, shortname, encode
    )
    SELECT
      sq_obj_enumerations_values.NEXTVAL,
      0,
      s.omp_name,
      l_rel_enum_id
    FROM
      sepo_std_schemes s
    WHERE
        s.f_level IN (3726, 4208)
      AND
        NOT EXISTS (
          SELECT 1 FROM obj_enumerations_values v
          WHERE
              v.encode = l_rel_enum_id
            AND
              v.shortname = s.omp_name
        );

    -- создание схем
    FOR i IN (
      SELECT
        id_record,
        r.id_table,
        omp_name,
        v.code AS id_value
      FROM
        sepo_std_schemes s,
        sepo_std_records r,
        obj_enumerations_values v
      WHERE
          s.f_level IN (3726, 4208)
        AND
          s.id_record = r.id
        AND
          v.encode = l_rel_enum_id
        AND
          s.omp_name = v.shortname(+)

    ) LOOP
      DELETE FROM obj_types_schemes
      WHERE
        objtype = 33 AND name = '@' || i.omp_name;

      -- схема
      l_scheme_id := pkg_sepo_system_objects.createscheme(
        pkg_sepo_system_objects.std_fixture,
        '@' || i.omp_name,
        0,
        i.omp_name
        );

      -- зависимость схемы от атрибута
      pkg_sepo_system_objects.createschemefilter(
        l_scheme_id,
        l_rel_attr_id,
        i.id_value
        );

      -- добавить атрибут в схему
      FOR j IN (
        SELECT
          omp_attr
        FROM
          sepo_std_attrs
        WHERE
            id_table = i.id_table
      ) LOOP
        pkg_sepo_system_objects.addattrtoscheme(
          l_scheme_id,
          l_group_id,
          j.omp_attr
          );

      END LOOP;

      -- добавеление атрибутов foxpro в схему
      FOR j IN (
        SELECT
          attrcode
        FROM
          sepo_std_foxpro_attrs_temp

      ) LOOP
        pkg_sepo_system_objects.addattrtoscheme(
          l_scheme_id,
          l_foxpro_group_id,
          j.attrcode
        );

      END LOOP;

      ImportLog('Создание схемы: ' || '@' || i.omp_name);

      COMMIT;

    END LOOP;

    -- 4 класс атрибутов, параметры ТП

    CreateStdAttrView();

  END;

  PROCEDURE SetOldFixObjParams
  IS
    l_attr_id NUMBER;
  BEGIN
    -- создание атрибутов FoxPro
    FOR i IN (
      SELECT * FROM sepo_std_foxpro_attrs
    ) LOOP
--      Dbms_Output.put_line(i.name || ' ' || i.shortname || ' ' || i.type_);
      l_attr_id := createfixattr(
        31,
        i.name,
        i.shortname,
        i.type_,
        NULL
      );

      l_attr_id := createfixattr(
        32,
        i.name,
        i.shortname,
        i.type_,
        NULL
      );

    END LOOP;

    -- Table
    l_attr_id := createfixattr(31, 'Table', 'Table', 1, NULL);
    -- RecKey
    l_attr_id := createfixattr(31, 'RecKey', 'RecKey', 3, NULL);
    -- TBLKey
    l_attr_id := createfixattr(31, 'TBLKey', 'TBLKey', 3, NULL);
    -- О_ВО
    l_attr_id := createfixattr(31, 'О_ВО', 'О_ВО', 1, NULL);

    -- Table
    l_attr_id := createfixattr(32, 'Table', 'Table', 1, NULL);
    -- RecKey
    l_attr_id := createfixattr(32, 'RecKey', 'RecKey', 3, NULL);
    -- TBLKey
    l_attr_id := createfixattr(32, 'TBLKey', 'TBLKey', 3, NULL);
    -- О_ВО
    l_attr_id := createfixattr(32, 'О_ВО', 'О_ВО', 1, NULL);

  END;

  FUNCTION CreateGost (
    p_name VARCHAR2,
    p_state NUMBER,
    p_owner NUMBER,
    p_user NUMBER,
    p_date DATE := SYSDATE,
    p_gostcode NUMBER := NULL
  )
  RETURN NUMBER
  IS
    l_prodcode NUMBER;
    l_bocode NUMBER;
    l_gostcode NUMBER;
    l_prodhistory NUMBER;
    l_promcode NUMBER;
    l_username user_list.fullname%TYPE;
  BEGIN
    l_prodcode := sq_production.NEXTVAL;

    INSERT INTO bo_production (
      code, Sign, TYPE
    )
    VALUES (
      l_prodcode, p_name, 256
    );

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, num
    )
    VALUES (
      l_bocode, 256, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_256 (
      socode
    )
    VALUES (
      l_bocode
    );

    IF p_gostcode IS NOT NULL THEN
      l_gostcode := p_gostcode;

    ELSE
      l_gostcode := sq_maretial_gosts.NEXTVAL;

      INSERT INTO maretial_gosts (
        code, name, recuser, recdate, modifyuser, modifydate
      )
      VALUES (
        l_gostcode, p_name, p_user, p_date, p_user, p_date
      );

    END IF;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 256, l_gostcode, p_owner, NULL, p_name, 0, NULL,
      l_prodcode, NULL, p_state, p_date, p_user,
      p_date, p_user
    );

    l_prodhistory := sq_bo_prod_history.NEXTVAL;

    INSERT INTO bo_production_history (
      code, prodcode, revision, bocode, insertdate, deletedate, action,
      usercode, promcode
    )
    VALUES (
      l_prodhistory, l_prodcode, 0, l_bocode, p_date, NULL, 0,
      p_user, NULL
    );

    UPDATE business_objects
    SET
      today_prodbocode = l_bocode,
      today_proddoccode = l_gostcode
    WHERE
        prodcode = l_prodcode;

    UPDATE bo_production
    SET
      today_prodbocode = l_bocode,
      today_proddoccode = l_gostcode
    WHERE
        code = l_prodcode;

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    SELECT fullname INTO l_username FROM user_list WHERE code = p_user;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, p_date, p_date,
      NULL, p_state, NULL, p_date, p_date, 0, 0, NULL, l_promcode
    );

    RETURN l_gostcode;

  END;

  PROCEDURE ImportStdGosts (
    p_owner NUMBER,
    p_state NUMBER
  )
  IS
    l_gost NUMBER;
  BEGIN
    -- корректировка стандартов в системе
    FOR i IN (
      SELECT
        g.code,
        g.name,
        g.recuser,
        g.recdate
      FROM
        maretial_gosts g
      WHERE
          g.code IN (
            SELECT
              Min(g_.code)
            FROM
              maretial_gosts g_
            WHERE
                g_.name = g.name
          )
        AND
          NOT EXISTS (
            SELECT
              1
            FROM
              bo_production b
            WHERE
                b.Sign = g.name
              AND
                b.TYPE = 256
        )

    ) LOOP
      ImportLog('Корректировка стандарта: ' || i.name);

      l_gost := CreateGost(
        i.name,
        p_state,
        p_owner,
        i.recuser,
        i.recdate,
        i.code
        );

      ImportLog('Скорректирован стандарт: ' || i.name);

    END LOOP;

    -- стандарты из файла
    FOR i IN (
      SELECT
        g.gost
      FROM
        v_sepo_std_gosts g
      WHERE
          g.gost IS NOT NULL
        AND
          NOT EXISTS (
            SELECT
              1
            FROM
              bo_production b
            WHERE
                b.Sign = g.gost
              AND
                b.TYPE = 256
          )
      GROUP BY
        g.gost

    ) LOOP
      ImportLog('Добавляется стандарт: ' || i.gost);

      l_gost := CreateGost(
        i.gost,
        p_state,
        p_owner,
        -2
        );

      ImportLog('Добавлен стандарт: ' || i.gost);

    END LOOP;

  END;

  PROCEDURE LoadStdFixture(
    p_type_default NUMBER,
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
  )
  IS
    l_counter NUMBER;
--    TYPE typecounterlist IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--    l_typelist typecounterlist;
    l_sign VARCHAR2(100);
--    l_num NUMBER;

    l_date DATE := SYSDATE;
    l_prod_code NUMBER;
    l_bo_code NUMBER;
    l_ko_code NUMBER;
    l_prod_history NUMBER;
    l_prom_code NUMBER;
    l_so_code NUMBER;
    l_description stockobj.description%TYPE;
    l_exists NUMBER;
    l_attr_relative VARCHAR2(20);
    l_enum_relative VARCHAR2(20);
  BEGIN
    -- выбор настроек
    SELECT
      attr_relative,
      enum_relative
    INTO
      l_attr_relative,
      l_enum_relative
    FROM
      sepo_std_import_settings;

    -- связь атрибутов и схем
    DELETE FROM sepo_std_attrs_temp;

    INSERT INTO sepo_std_attrs_temp (
      id_record, attr_name, attr_type, attr_value, enum_code
    )
    SELECT
      c.id_record,
      t.shortname,
      t.attr_type,
      c.field_value,
      v.code
    FROM
      sepo_std_table_rec_contents c
      JOIN
      v_sepo_std_attrs a
      ON
          c.id_field = a.id_attr
      JOIN
      obj_attributes t
      ON
          t.objtype = 33
        AND
          t.name = a.omp_name
      left JOIN
      obj_enumerations_values v
      ON
          a.id_omp_enum = v.encode
        AND
          v.shortname = c.field_value;

    -- счетчик для обозначения
--    l_typelist.DELETE();

--    FOR i IN (
--      SELECT
--        lvl_type
--      FROM
--        v_sepo_std_import
--      WHERE
--          lvl_classify IN (3726, 4208)
--      GROUP BY
--        lvl_type
--      UNION ALL
--      SELECT
--        4208
--      FROM
--        dual
--    ) LOOP
--      l_typelist(i.lvl_type) := 0;

--    END LOOP;

    FOR i IN (
      SELECT code, name FROM sepo_std_folder_codes c
      WHERE
          NOT EXISTS (
            SELECT 1 FROM fixture_types t
            WHERE
                t.name = c.name
          )
    ) LOOP
      INSERT INTO fixture_types (
        code, name, shortname
      )
      VALUES (
        sq_fixture_types.NEXTVAL, i.name, i.code
      );

    END LOOP;

    l_counter := 7999999;
    -- импорт
    FOR i IN (
      SELECT
        i.lvl_type,
        i.id_record,
        i.reckey,
        i.tblkey,
        i.f_table,
        i.name,
        i.sign_vo,
        coalesce(c.key_, 0) AS lvlkey,
        coalesce(t.code, p_type_default) AS typecode,
        i.scheme_name,
        v.code AS scheme_code,
        i.gost
      FROM
        v_sepo_std_import i,
        sepo_std_folder_codes c,
        fixture_types t,
        obj_enumerations e,
        obj_enumerations_values v
      WHERE
          i.lvl_classify IN (3726, 4208)
        AND
          i.lvl_type = c.id_folder(+)
        AND
          c.name = t.name(+)
        AND
          e.name = l_enum_relative
        AND
          v.encode = e.code
        AND
          v.shortname = i.scheme_name
      ORDER BY
        reckey,
        tblkey
    ) LOOP
      ImportLog('Загружается оснастка: ' || i.name);

--      l_typelist(i.lvl_type) := l_typelist(i.lvl_type) + 1;
--      l_num := l_typelist(i.lvl_type);

--      l_sign := '80' || i.lvlkey || LPad('0', 4 - Length(l_num), '0') || l_num;
      l_counter := l_counter + 1;
      l_sign := l_counter;

      SELECT
        Count(1)
      INTO
        l_exists
      FROM
        bo_production
      WHERE
          TYPE = 33
        AND
          Sign = l_sign;

      IF l_exists > 0 THEN
        ImportLog('Оснастка: ' || i.name || ' уже существует в базе!');
        CONTINUE;

      END IF;

      l_prod_code := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_prod_code, l_sign, 33
      );

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bo_code, 1000090, NULL, so.GetNextSoNum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bo_code
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_prod_code, l_bo_code
      );

      l_bo_code := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bo_code, 33, NULL, so.GetNextSoNum()
      );

      -- инициализация атрибутов
      pkg_sepo_attr_operations.Init(33);

      pkg_sepo_attr_operations.addAttr('Table', i.f_table);
      pkg_sepo_attr_operations.addAttr('RecKey', i.reckey);
      pkg_sepo_attr_operations.addAttr('TBLKey', i.tblkey);
      pkg_sepo_attr_operations.addAttr('О_ВО', i.sign_vo);
      pkg_sepo_attr_operations.addAttr(l_attr_relative, i.scheme_code);

      FOR j IN (
        SELECT
          attr_name,
          attr_type,
          attr_value,
          enum_code
        FROM
          sepo_std_attrs_temp
        WHERE
            id_record = i.id_record
      ) LOOP
--        Dbms_Output.put_line(j.attr_name || ' ' || j.attr_value);

        IF j.attr_type IN (2,3) THEN
          pkg_sepo_attr_operations.addAttr(
            j.attr_name,
            To_Number(REPLACE(j.attr_value, ',', '.'))
            );

        ELSIF j.attr_type = 10 THEN
          pkg_sepo_attr_operations.addAttr(
            j.attr_name,
            j.enum_code
            );

        ELSE
          pkg_sepo_attr_operations.addAttr(
            j.attr_name,
            j.attr_value
            );

        END IF;

      END LOOP;

      pkg_sepo_attr_operations.genInsertSql();
      pkg_sepo_attr_operations.insertAttrs(l_bo_code);

      INSERT INTO obj_attr_values_33_2 (socode) VALUES (l_bo_code);

      l_ko_code := sq_unvcode.NEXTVAL;

      INSERT INTO business_objects
      (code, TYPE, doccode, owner, checkout, name, revision, revsign,
        prodcode, access_level, today_state, today_statedate, today_stateuser,
          create_date, create_user
          )
      VALUES
      (l_bo_code, 33, l_ko_code, p_owner, NULL, l_sign, 0, NULL,
        l_prod_code, NULL, p_state, l_date, -2,
          l_date, -2);

      l_prod_history := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history
      (code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode)
      VALUES
      (l_prod_history, l_prod_code, 0, l_bo_code, l_date, NULL, 0,
        -2, NULL);

      UPDATE business_objects
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          prodcode = l_prod_code;

      UPDATE bo_production
      SET
        today_prodbocode = l_bo_code,
        today_proddoccode = l_ko_code
      WHERE
          code = l_prod_code;

      INSERT INTO konstrobj (
        unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
        kind, supplytype, owner, protection, recdate, meascode, revision,
        prodcode, formedfrom, formedtype)
      VALUES (
        l_ko_code, l_ko_code, 33, l_bo_code, 0, l_sign, i.name, NULL, -1,
        NULL, 2, p_owner, 0, l_date, p_meascode, 0,
        l_prod_code, NULL, NULL
      );

      INSERT INTO standarts (
        code, kotype, sign, name, notice, suppcode, owner, protection,
        recdate, make
      )
      VALUES (
        l_ko_code, 33, l_sign, i.name, NULL, 2, p_owner, 0,
        l_date, SubStr(i.gost, 1, Least(Length(i.gost), 35))
      );

      INSERT INTO fixture_base (
        code, kotype, fixture_types_code, originalname
      )
      VALUES (
        l_ko_code, 33, i.typecode, l_sign
      );

      l_so_code := sq_stockobj.NEXTVAL;
      l_description := l_sign || ' ' || i.name;

      INSERT INTO stockobj (
        code, basetype, basecode, SUBTYPE, fk_bo_production, description,
        desc_date, desc_fmt, meascode, desc_update_check, is_annul,
        recdate, owner, notice, attr, Sign, name, unvcode,
        mat_state, socode
      )
      VALUES (
        l_so_code, 0, l_prod_code, 33, l_prod_code, l_description,
        l_date, NULL, p_meascode, 0, 0,
        l_date, p_owner, NULL, 1, l_sign, i.name, l_ko_code,
        NULL, l_bo_code
      );

      l_prom_code := sq_businessobj_promotion_code.NEXTVAL;

      INSERT INTO businessobj_promotion (
        code, businessobj, operation, usercode, lastname, donedate, rdate,
        prev_state, current_state, note, statedate, todate, action,
        revision, iicode, mainpromcode
      )
      VALUES (
        l_prom_code, l_bo_code, NULL, -2, 'OMP Администратор', l_date, l_date,
        NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_prom_code
      );

      ImportLog('Загружена оснастка: ' || i.name);

    END LOOP;

  END;

  PROCEDURE BuildStdClassify_pvt (
    p_classify NUMBER,
    p_parent NUMBER,
    p_omp_parent NUMBER
  )
  IS
    l_group NUMBER;
    l_tblgroup NUMBER;
  BEGIN
    FOR j IN (
      SELECT
        r.f_key AS id_record,
        r.f_level,
        t.f_descr
      FROM
        sepo_std_records r,
        sepo_std_tables t
      WHERE
          t.id = r.id_table
        AND
          r.f_level = p_parent
    ) LOOP
      l_tblgroup := AddClassifyGroup(
        p_classify,
        j.f_level,
        j.f_descr,
        j.f_level,
        p_omp_parent
      );

      FOR k IN (
        SELECT
          t.fixcode
        FROM
          sepo_std_tech_attrs_temp t
        WHERE
            t.reckey = j.id_record
      ) LOOP
        INSERT INTO fixture_to_group (
          fixturecode, groupcode
        )
        VALUES (
          k.fixcode, l_tblgroup
        );

      END LOOP;

    END LOOP;

    FOR i IN (
      SELECT
        f.f_level,
        f.f_name,
        c.key_
      FROM
        sepo_std_folders f,
        sepo_std_folder_codes c
      WHERE
          f.f_level = c.id_folder(+)
        AND
          f.f_owner = p_parent
    ) LOOP
      l_group := AddClassifyGroup(
        p_classify,
        Nvl(i.key_, i.f_level),
        i.f_name,
        i.f_level,
        p_omp_parent
        );

      BuildStdClassify_pvt(p_classify, i.f_level, l_group);

    END LOOP;

  END;

  PROCEDURE CreateStdClassify (
    p_name VARCHAR2,
    p_owner NUMBER,
    p_level NUMBER
  )
  IS
    l_attrcode NUMBER;
    l_classify NUMBER;
  BEGIN
    DELETE FROM sepo_std_tech_attrs_temp;

    l_attrcode := pkg_sepo_attr_operations.getcode(33, 'RecKey');

    EXECUTE IMMEDIATE
      'INSERT INTO sepo_std_tech_attrs_temp (' ||
        'fixcode, reckey' ||
      ')' ||
      'SELECT ' ||
        'b.doccode,' ||
        't_33.a_' || l_attrcode ||
      ' FROM ' ||
        'obj_attr_values_33 t_33,' ||
        'business_objects b ' ||
      'WHERE ' ||
          'b.code = t_33.socode';

    l_classify := sq_classify.NEXTVAL;

    INSERT INTO classify (
      code, clcode, cltype, clname, owner
    )
    VALUES (
      l_classify, p_name, 2, p_name, p_owner
    );

    BuildStdClassify_pvt(l_classify, p_level, NULL);

  END;

  PROCEDURE CreateOldFixtureClassify (
    p_name VARCHAR2,
    p_owner NUMBER,
    p_level NUMBER
  )
  IS
    l_attrcode NUMBER;
    l_classify NUMBER;
  BEGIN
    DELETE FROM sepo_std_tech_attrs_temp;

    l_attrcode := pkg_sepo_attr_operations.getcode(32, 'RecKey');

    EXECUTE IMMEDIATE
      'INSERT INTO sepo_std_tech_attrs_temp (' ||
        'fixcode, reckey' ||
      ')' ||
      'SELECT ' ||
        'b.doccode,' ||
        't_32.a_' || l_attrcode ||
      ' FROM ' ||
        'obj_attr_values_32 t_32,' ||
        'business_objects b ' ||
      'WHERE ' ||
          'b.code = t_32.socode';

    l_classify := sq_classify.NEXTVAL;

    INSERT INTO classify (
      code, clcode, cltype, clname, owner
    )
    VALUES (
      l_classify, p_name, 2, p_name, p_owner
    );

    BuildStdClassify_pvt(l_classify, p_level, NULL);

  END;

  PROCEDURE LoadOldFixture (
    p_type_default NUMBER,
    p_owner NUMBER,
    p_meascode NUMBER,
    p_state NUMBER
  )
  IS
    l_fixcode NUMBER;
    l_fixtype NUMBER;
    l_date DATE := SYSDATE;
    l_prod_code NUMBER;
    l_bo_code NUMBER;
    l_ko_code NUMBER;
    l_prod_history NUMBER;
    l_prom_code NUMBER;
    l_so_code NUMBER;
    l_description stockobj.description%TYPE;
    l_counter NUMBER;
  BEGIN
    --
    DELETE FROM sepo_std_import_temp;

    INSERT INTO sepo_std_import_temp (
      id_record, id_parent_record, lvl_classify, lvl_type,
      f_level, reckey, tblkey, f_table, name, sign_vo, name_vo,
      scheme_name, gost
    )
    SELECT
      *
    FROM
      v_sepo_std_import
    WHERE
        lvl_classify = 3709;

    -- для оснастки с пустым обозначением генерируется код,
    -- начиная с 8100000
    l_counter := 8099999;

    -- запрос загрузки оснастки
    FOR i IN (
      SELECT
        reckey,
        tblkey,
        f_table,
        name_vo AS name,
        sign_vo AS designation
      FROM
        sepo_std_import_temp i
      WHERE
          sign_vo IN
          (
            SELECT
              i_.sign_vo
            FROM
              sepo_std_import_temp i_
            WHERE
                i_.sign_vo = i.sign_vo
            GROUP BY
              i_.sign_vo
            HAVING
              Count(DISTINCT i_.id_record) = 1
          )
        OR
          sign_vo IS NULL
      ORDER BY
        sign_vo

    ) LOOP
      SELECT
        Max(code),
        Max(type)
      INTO
        l_fixcode,
        l_fixtype
      FROM
        business_objects b
      WHERE
          b.TYPE IN (31,32)
        AND
          b.name = i.designation;

      -- оснастка с пустым обозначением
      IF i.designation IS NULL THEN
        l_counter := l_counter + 1;
        i.designation := l_counter;

      END IF;

      IF l_fixcode IS NULL THEN

        l_prod_code := sq_production.NEXTVAL;

        INSERT INTO bo_production
        (code, Sign, TYPE)
        VALUES
        (l_prod_code, i.designation, 32);

        l_bo_code := sq_business_objects_code.NEXTVAL;

        INSERT INTO omp_objects
        (code, objtype, scheme, num)
        VALUES
        (l_bo_code, 1000090, NULL, so.GetNextSoNum());

        INSERT INTO obj_attr_values_1000090
        (socode)
        VALUES
        (l_bo_code);

        INSERT INTO okp_boproduction_params
        (prodcode, socode)
        VALUES
        (l_prod_code, l_bo_code);

        l_bo_code := sq_business_objects_code.NEXTVAL;

        INSERT INTO omp_objects
        (code, objtype, scheme, num)
        VALUES
        (l_bo_code, 32, NULL, so.GetNextSoNum());

        -- инициализация атрибутов
        pkg_sepo_attr_operations.init(32);

        pkg_sepo_attr_operations.addattr('Table', i.f_table);
        pkg_sepo_attr_operations.addattr('RecKey', i.reckey);
        pkg_sepo_attr_operations.addattr('TBLKey', i.tblkey);
        pkg_sepo_attr_operations.addattr('О_ВО', i.designation);
        pkg_sepo_attr_operations.geninsertsql();

        pkg_sepo_attr_operations.insertattrs(l_bo_code);

        l_ko_code := sq_unvcode.NEXTVAL;

        INSERT INTO business_objects
        (code, TYPE, doccode, owner, checkout, name, revision, revsign,
          prodcode, access_level, today_state, today_statedate, today_stateuser,
            create_date, create_user
            )
        VALUES
        (l_bo_code, 32, l_ko_code, p_owner, NULL, i.designation, 0, NULL,
          l_prod_code, NULL, p_state, l_date, -2,
            l_date, -2);

        l_prod_history := sq_bo_prod_history.NEXTVAL;

        INSERT INTO bo_production_history
        (code, prodcode, revision, bocode, insertdate, deletedate, action,
          usercode, promcode)
        VALUES
        (l_prod_history, l_prod_code, 0, l_bo_code, l_date, NULL, 0,
          -2, NULL);

        UPDATE business_objects
        SET
          today_prodbocode = l_bo_code,
          today_proddoccode = l_ko_code
        WHERE
            prodcode = l_prod_code;

        UPDATE bo_production
        SET
          today_prodbocode = l_bo_code,
          today_proddoccode = l_ko_code
        WHERE
            code = l_prod_code;

        INSERT INTO konstrobj
        (unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
          kind, supplytype, owner, protection, recdate, meascode, revision,
            prodcode, formedfrom, formedtype)
        VALUES
        (l_ko_code, l_ko_code, 32, l_bo_code, 0, i.designation, i.name, NULL, -1,
          NULL, 0, p_owner, 0, l_date, p_meascode, 0,
            l_prod_code, NULL, NULL);

        INSERT INTO details
        (code, kotype, Sign, name, notice, suppcode, owner, protection,
          recdate, format, stocknumber)
        VALUES
        (l_ko_code, 32, i.designation, i.name, NULL, 0, p_owner, 0,
          l_date, NULL, NULL);

        INSERT INTO fixture_base
        (code, kotype, fixture_types_code, originalname)
        VALUES
        (l_ko_code, 32, p_type_default, i.designation);

        l_so_code := sq_stockobj.NEXTVAL;
        l_description := i.designation || ' ' || i.name;

        INSERT INTO stockobj
        (code, basetype, basecode, SUBTYPE, fk_bo_production, description,
          desc_date, desc_fmt, meascode, desc_update_check, is_annul,
            recdate, owner, notice, attr, Sign, name, unvcode,
              mat_state, socode)
        VALUES
        (l_so_code, 0, l_prod_code, 32, l_prod_code, l_description,
          l_date, NULL, p_meascode, 0, 0,
            l_date, p_owner, NULL, 1, i.designation, i.name, l_ko_code,
              NULL, l_so_code);

        l_prom_code := sq_businessobj_promotion_code.NEXTVAL;

        INSERT INTO businessobj_promotion
        (code, businessobj, operation, usercode, lastname, donedate, rdate,
          prev_state, current_state, note, statedate, todate, action,
            revision, iicode, mainpromcode)
        VALUES
        (l_prom_code, l_bo_code, NULL, -2, 'OMP Администратор', l_date, l_date,
          NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_prom_code);

        ImportLog(i.designation || ': добавлена оснастка');

      ELSE
        pkg_sepo_attr_operations.init(l_fixtype);

        pkg_sepo_attr_operations.addattr('Table', i.f_table);
        pkg_sepo_attr_operations.addattr('RecKey', i.reckey);
        pkg_sepo_attr_operations.addattr('TBLKey', i.tblkey);
        pkg_sepo_attr_operations.updateattrs(l_fixcode);

        ImportLog(i.designation || ': обновлены атрибуты');

      END IF;

    END LOOP;

  END;

  PROCEDURE DeleteStdFixture
  IS
    l_attrcode NUMBER;
    n NUMBER;
  BEGIN
    DELETE FROM sepo_std_tech_attrs_temp;
    l_attrcode := pkg_sepo_attr_operations.getcode(33, 'RecKey');

    EXECUTE IMMEDIATE
      'INSERT INTO sepo_std_tech_attrs_temp (' ||
        'fixcode, reckey' ||
      ')' ||
      'SELECT ' ||
        'b.doccode,' ||
        't_33.a_' || l_attrcode ||
      ' FROM ' ||
        'obj_attr_values_33 t_33,' ||
        'business_objects b ' ||
      'WHERE ' ||
          'b.code = t_33.socode';

    FOR i IN (
      SELECT
        b.code AS bocode,
        b.doccode AS kocode,
        b.prodcode,
        pm.socode AS paramcode,
        s.code AS stockcode,
        b.name AS bname
      FROM
        business_objects b,
        okp_boproduction_params pm,
        stockobj s,
        sepo_std_tech_attrs_temp ta
      WHERE
          pm.prodcode = b.prodcode
        AND
          s.fk_bo_production = b.prodcode
        AND
          ta.fixcode = b.doccode
        AND
          b.TYPE = 33
        AND
          ta.reckey IS NOT NULL

    ) LOOP
      DELETE FROM okp_boproduction_params WHERE prodcode = i.prodcode;
      DELETE FROM obj_attr_values_1000090 WHERE socode = i.paramcode;
      DELETE FROM omp_objects WHERE code = i.paramcode;

      DELETE FROM stockobj WHERE code = i.stockcode;
      DELETE FROM businessobj_promotion WHERE businessobj = i.bocode;
      DELETE FROM business_objects WHERE code = i.bocode;
      DELETE FROM fixture_base WHERE code = i.kocode;
      DELETE FROM standarts WHERE code = i.kocode;
      DELETE FROM konstrobj WHERE unvcode = i.kocode;
      DELETE FROM bo_production_history WHERE prodcode = i.prodcode;
      DELETE FROM bo_production WHERE code = i.prodcode;
      DELETE FROM obj_attr_values_33 WHERE socode = i.bocode;
      DELETE FROM obj_attr_values_33_2 WHERE socode = i.bocode;
      DELETE FROM omp_objects WHERE code = i.bocode;

      ImportLog('Стандартная оснастка: ' || i.bname || ' удалена');

    END LOOP;

  END;

  FUNCTION TpImportValidate (p_tp NUMBER, p_tptype NUMBER) RETURN BOOLEAN
  IS
    l_count NUMBER;
  BEGIN
    IF p_tptype IN (0,2) THEN
      SELECT
        Count(1)
      INTO
        l_count
      FROM
        sepo_tp_to_dce d,
        bo_production b,
        ko_types t
      WHERE
          d.designation = b.Sign
        AND
          t.code = b.TYPE
        AND
          d.id_tp = p_tp;

      IF l_count = 0 THEN
        INSERT INTO sepo_tp_errors (
          id_tp, id_cause
        )
        VALUES (
          p_tp, 1
        );

        RETURN FALSE;

      END IF;

    END IF;

    SELECT
      Count(1)
    INTO
      l_count
    FROM
      sepo_tp_opers op,
      technology_operations top
    WHERE
        top.description = op.reckey
      AND
        op.id_tp = p_tp;

    IF l_count = 0 THEN
      INSERT INTO sepo_tp_errors (
        id_tp, id_cause
      )
      VALUES (
        p_tp, 2
      );

      RETURN FALSE;

    END IF;

    SELECT
      Count(1)
    INTO
      l_count
    FROM
      sepo_tp_fields f,
      sepo_tp_exclude_authors a
    WHERE
        f.f_value = a.author
      AND
        field_name IN ('ФИО', 'ФИО1')
      AND
        f.id_tp = p_tp;

    IF l_count > 0 THEN
      INSERT INTO sepo_tp_errors (
        id_tp, id_cause
      )
      VALUES (
        p_tp, 3
      );

      RETURN FALSE;

    END IF;

    RETURN TRUE;

  END;

  PROCEDURE SaveImportTpData
  IS
  BEGIN
    DELETE FROM sepo_tp_opers_temp;
    DELETE FROM sepo_tp_instructions_temp;
    DELETE FROM sepo_tp_workers_temp;
    DELETE FROM sepo_tp_equipments_temp;
    DELETE FROM sepo_tp_steps_temp;
    DELETE FROM sepo_tp_tools_temp;

    INSERT INTO sepo_tp_opers_temp (
      id_op, id_tp, key_, reckey, order_, date_, num, place, tpkey,
      opercode, opername, cex, instruction, remark, topcode, wscode
    )
    SELECT
      id_op,
      id_tp,
      key_,
      reckey,
      order_,
      date_,
      num,
      place,
      tpkey,
      opercode,
      opername,
      cex,
      instruction,
      remark,
      topcode,
      wscode
    FROM
      v_sepo_tp_opers;

    INSERT INTO sepo_tp_instructions_temp (
      stdcode, f_level
    )
    SELECT
      i.code,
      s.f_level
    FROM
      v_sepo_instructions_tb s,
      instructions i
    WHERE
        s.instruction = i.Sign;

    INSERT INTO sepo_tp_workers_temp (
      ompcode, category, cnt, operkey, perehkey
    )
    SELECT
      ompcode,
      category,
      cnt,
      operkey,
      perehkey
    FROM
      v_sepo_tp_workers;

    INSERT INTO sepo_tp_equipments_temp (
      ompcode, operkey
    )
    SELECT
      ompcode,
      operkey
    FROM
      v_sepo_tp_equipments;

    INSERT INTO sepo_tp_steps_temp (
      id_step, operkey, stepname, stepnumber, remark, ompcode, perehkey
    )
    SELECT
      id_step,
      operkey,
      stepname,
      stepnumber,
      remark,
      ompcode,
      perehkey
    FROM
      v_sepo_tp_steps;

    INSERT INTO sepo_tp_tools_temp (
      id_tool, tool_code, operkey, perehkey,
      count_, norm, ordernum
    )
    SELECT
      id,
      unvcode,
      operkey,
      perehkey,
      1,
      norm,
      order_
    FROM
      v_sepo_tp_fixture_3709
    UNION ALL
    SELECT
      id,
      unvcode,
      operkey,
      perehkey,
      1,
      norm,
      order_
    FROM
      v_sepo_tp_fixture_old
    UNION ALL
    SELECT
      id,
      unvcode,
      operkey,
      perehkey,
      1,
      norm,
      order_
    FROM
      v_sepo_tp_fixture_std;

  END;

  PROCEDURE ImportTp (
    p_groupcode NUMBER,
    p_letter NUMBER,
    p_state NUMBER,
    p_owner NUMBER
  )
  IS
    l_tpgroupcode NUMBER;
    l_opergroupcode NUMBER;
    l_tpcode NUMBER;
    l_counter NUMBER;
    l_tptoko NUMBER;
    l_operation NUMBER;
    l_stepcode NUMBER;
    l_perfcode NUMBER;
    l_fixopercode NUMBER;
    l_fixstepcode NUMBER;
    l_eqpopercode NUMBER;
  BEGIN
    SaveImportTpData();

    DELETE FROM sepo_tp_errors;

    FOR i IN (
      SELECT
        *
      FROM
        v_sepo_tech_processes
      WHERE
--          tptype IN (1,3)
--        AND
--          designation = '6Б8.366.131-06 М2 ТП'
--        AND
--          id = 35859
--        AND
          NOT EXISTS (
            SELECT
              1
            FROM
              bo_production b
            WHERE
                b.TYPE = 60
              AND
                b.Sign = designation
          )
--        AND
--          id = 37856

    ) LOOP
      IF NOT pkg_sepo_import_global.tpimportvalidate(i.id, i.tptype) THEN CONTINUE; END IF;

      pkg_sepo_import_global.importlog(
        'ТП ' || i.designation || ' загружается'
      );

      IF i.tptype IN (0, 1, 3) THEN
        l_tpgroupcode := p_groupcode;
        l_opergroupcode := NULL;
      ELSE
        l_tpgroupcode := NULL;
        l_opergroupcode := p_groupcode;

      END IF;

      -- создание ТП
      l_tpcode := pkg_sepo_techprocesses.createtp(
        i.tptype,
        i.designation,
        i.name,
        NULL,
        l_tpgroupcode,
        p_letter,
        p_state,
        p_owner,
        i.remark
      );

      l_counter := 1;

      -- связь с КД
      FOR j IN (
        SELECT
          b.today_proddoccode AS unvcode
        FROM
          sepo_tp_to_dce d,
          bo_production b,
          ko_types t
        WHERE
            d.designation = b.Sign
          AND
            t.code = b.TYPE
          AND
            d.id_tp = i.id

      ) LOOP
        l_tptoko := pkg_sepo_techprocesses.linktptoko(
          l_tpcode,
          0,
          j.unvcode,
          l_counter
        );

        l_counter := l_counter + 1;

      END LOOP;

      -- операции
      FOR j IN (
        SELECT
          *
        FROM
          sepo_tp_opers_temp
        WHERE
            id_tp = i.id
          AND
            num IS NOT NULL
          AND
            Length(num) < 5
        ORDER BY
          order_
      ) LOOP
        l_operation := pkg_sepo_techprocesses.addoperation (
          l_tpcode,
          j.num,
          j.wscode,
          j.topcode,
          j.remark,
          0,
          l_opergroupcode,
          NULL
        );

        -- для групповых ТП
        IF i.tptype = 3 THEN
          pkg_sepo_techprocesses.linkopertoko(l_operation);
        END IF;

        -- инструкции на операцию
        FOR k IN (
          SELECT
            stdcode
          FROM
            sepo_tp_instructions_temp
          WHERE
              f_level = j.instruction
        ) LOOP
          pkg_sepo_techprocesses.addinstruction (
            l_operation,
            k.stdcode,
            0
          );

        END LOOP;

        l_counter := 0;

        FOR k IN (
          SELECT
            ompcode,
            category,
            cnt
          FROM
            sepo_tp_workers_temp
          WHERE
              perehkey = 0
            AND
              operkey = j.key_
            AND
              category IS NOT NULL
        ) LOOP
          pkg_sepo_techprocesses.addperformeronoper (
            l_operation,
            k.category,
            k.ompcode,
            k.cnt,
            l_counter,
            l_perfcode
          );

          l_counter := l_counter + 1;

          -- связь с КО для типовых и групповых ТП
          IF i.tptype = 1 THEN

            FOR l IN (
              SELECT
                code
              FROM
                techproc_to_kobj
              WHERE
                  tpcode = l_tpcode
            ) LOOP
              pkg_sepo_techprocesses.linkperformertoko(l_perfcode, l.code);

            END LOOP;

          ELSIF i.tptype = 3 THEN
            FOR l IN (
              SELECT
                code
              FROM
                techoper_to_kobj
              WHERE
                  tpopercode = l_operation
            ) LOOP
              pkg_sepo_techprocesses.linkperformertooperko(l_perfcode, l.code);

            END LOOP;

          END IF;


        END LOOP;

        l_counter := 0;

        -- модели оборудования на операцию
        FOR k IN (
          SELECT
            ompcode
          FROM
            sepo_tp_equipments_temp
          WHERE
              operkey = j.key_
          GROUP BY
            ompcode
        ) LOOP
          pkg_sepo_techprocesses.addequipmentmodel (
            l_operation,
            k.ompcode,
            l_counter,
            l_eqpopercode
          );

          IF i.tptype = 3 THEN
            FOR l IN (
              SELECT
                code
              FROM
                techoper_to_kobj
              WHERE
                  tpopercode = l_operation
            ) LOOP
              pkg_sepo_techprocesses.linkequipmentmodeltooperko(
                l.code,
                l_eqpopercode
                );

            END LOOP;

          END IF;

          l_counter := l_counter + 1;

        END LOOP;

        -- оснастка на операцию
        FOR k IN (
          SELECT
            tool_code,
            count_,
            norm,
            ordernum
          FROM
            sepo_tp_tools_temp
          WHERE
              perehkey = 0
            AND
              operkey = j.key_

        ) LOOP
          pkg_sepo_techprocesses.addfixtureonoper (
            l_operation,
            k.tool_code,
            k.count_,
            k.norm,
            k.ordernum,
            l_fixopercode
          );

          IF i.tptype = 3 THEN
            FOR l IN (
              SELECT
                code
              FROM
                techoper_to_kobj
              WHERE
                  tpopercode = l_operation
            ) LOOP
              pkg_sepo_techprocesses.linkfixturetooperko(
                l_fixopercode,
                l.code,
                k.count_,
                k.norm
              );

            END LOOP;

          END IF;

        END LOOP;

        -- переходы на операцию
        FOR k IN (
          SELECT
            id_step,
            operkey,
            perehkey,
            SubStr(stepname, 1, 400) AS stepname,
            coalesce(stepnumber, -1) AS stepnumber,
            remark,
            ompcode
          FROM
            sepo_tp_steps_temp
          WHERE
              operkey = j.key_

        ) LOOP
          l_stepcode := pkg_sepo_techprocesses.addstep (
            l_operation,
            k.stepname,
            2,
            k.stepnumber,
            k.stepname,
            k.remark,
            k.ompcode
          );

          -- связь перехода с операцией для групповых ТП
          IF i.tptype = 3 THEN
            FOR l IN (
              SELECT
                code
              FROM
                techoper_to_kobj
              WHERE
                  tpopercode = l_operation
            ) LOOP
              pkg_sepo_techprocesses.linksteptoko(l_stepcode, l.code);

            END LOOP;

          END IF;

          l_counter := 0;

          FOR l IN (
            SELECT
              ompcode,
              category,
              cnt
            FROM
              sepo_tp_workers_temp
            WHERE
                operkey = j.key_
              AND
                perehkey = k.perehkey
              AND
                category IS NOT NULL
          ) LOOP
            pkg_sepo_techprocesses.addperformeronstep (
              l_stepcode,
              l.category,
              l.ompcode,
              l.cnt,
              l_counter,
              l_perfcode
            );

            IF i.tptype = 1 THEN
              FOR m IN (
                SELECT
                  code
                FROM
                  techproc_to_kobj
                WHERE
                    tpcode = l_tpcode
              ) LOOP
                pkg_sepo_techprocesses.linkstepperformertoko(l_perfcode, m.code);

              END LOOP;

            ELSE
              FOR m IN (
                SELECT
                  code
                FROM
                  techstep_to_kobj
                WHERE
                    tpstepcode = l_stepcode
              ) LOOP
                pkg_sepo_techprocesses.linkstepperformertooperko(l_perfcode, m.code);

              END LOOP;

            END IF;

            l_counter := l_counter + 1;

          END LOOP;

--          Dbms_Output.put_line(j.key_ || ' ' || k.perehkey);

          -- оснастка на переход
          FOR l IN (
            SELECT
              tool_code,
              count_,
              norm,
              ordernum
            FROM
              sepo_tp_tools_temp
            WHERE
                operkey = j.key_
              AND
                perehkey = k.perehkey

          ) LOOP
            pkg_sepo_techprocesses.addfixtureonstep (
              l_stepcode,
              l.tool_code,
              l.count_,
              l.norm,
              l.ordernum,
              l_fixopercode
            );

            IF i.tptype = 3 THEN
              FOR m IN (
                SELECT
                  code
                FROM
                  techstep_to_kobj
                WHERE
                    tpstepcode = l_stepcode
              ) LOOP
                pkg_sepo_techprocesses.linkstepfixturetooperko(
                  l_fixopercode,
                  m.code,
                  l.count_
                );

              END LOOP;

            END IF;


          END LOOP;


        END LOOP;


      END LOOP;

      pkg_sepo_import_global.importlog('ТП ' || i.designation || ' загружен' );

    END LOOP;

  END;

END;
/

