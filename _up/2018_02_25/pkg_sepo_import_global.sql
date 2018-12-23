PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_import_global
CREATE OR REPLACE PACKAGE pkg_sepo_import_global
AS
  -- пакет предназначен для импорта различных данных в КИС "Омега"

  classify_not_founded exception;

  -- справочник профессий
  PROCEDURE ClearProfessions;
  PROCEDURE LoadProfessions;

  -- справочник технологических операций
  PROCEDURE ClearOperCatalogs;
  PROCEDURE LoadOperCatalogs;
  PROCEDURE ClearOperations;
  PROCEDURE LoadOperations;

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

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_global
CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_global
AS
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

  PROCEDURE LoadOperations
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
      (code, opercode, variantcode, name, description)
      VALUES
      (sq_technology_operations.NEXTVAL, i.f1, i.suf_code, i.f_name, i.f_level);

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
          name = p_name
        AND
          HASH = p_hash;

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

END;
/

