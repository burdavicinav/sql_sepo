CREATE OR REPLACE PACKAGE pkg_sepo_import_global
AS
  -- ����� ������������ ��� ������� ��������� ������ � ��� "�����"

  classify_not_founded exception;

  -- ���������� ���������
  PROCEDURE ClearProfessions;
  PROCEDURE LoadProfessions;

  -- ���������� ��������������� ��������
  PROCEDURE ClearOperCatalogs;
  PROCEDURE LoadOperCatalogs;
  PROCEDURE ClearOperations;
  PROCEDURE LoadOperations;

  -- ���������� ��������������� ���������
  PROCEDURE ClearSteps;
  PROCEDURE LoadSteps;

  -- ���������� ������� ������������
  PROCEDURE ClearEqpModels(p_classify NUMBER);
  PROCEDURE LoadEqpModelCatalogs(p_classify NUMBER);
  PROCEDURE LoadEqpModels(p_owner NUMBER);
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_import_global
AS
  -- �������� ��� �������������� �� ��� ����
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

  -- �������� ��� �������������� ��������������� ��������
  FUNCTION GetOperClassifyCode RETURN NUMBER
  IS
  BEGIN
    RETURN GetClassifyCode(4);
  END;

  -- �������� ��� �������������� ��������������� ���������
  FUNCTION GetStepClassifyCode RETURN NUMBER
  IS
  BEGIN
    RETURN GetClassifyCode(6);
  END;

  -- �������� ������ � �������������
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

  -- ���������� �������������� ��������
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

  -- ���������� �������������� ���������
  PROCEDURE BuildStepClassify_pvt (
    p_classify NUMBER,
    p_parent NUMBER,
    p_omp_parent NUMBER,
    p_is_step IN OUT NUMBER,
    p_path IN OUT VARCHAR2,
    p_step_path IN OUT VARCHAR2,
    p_level IN OUT NUMBER,
    p_order IN OUT NUMBER
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
    -- ��������� ���� ��������������
    l_classify_code := GetStepClassifyCode();

    -- ���� �� ���������/���������
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
          AND
            t.f_type != 'OIT_Unknown'
      WHERE
          s.f_owner = p_parent
    ) LOOP
      -- ������ ���� �� �������� �� ��������
      l_path := p_path;

      IF p_path IS NULL THEN
        p_path := i.f_name;
      ELSE
        p_path := p_path || ' ' || i.f_name;
      END IF;

      -- ������� ��������
      l_is_step := p_is_step;
      IF i.id_text IS NOT NULL AND p_parent != 0 THEN p_is_step := 1; END IF;

      -- ���� �� �������
      l_step_path := p_step_path;

      IF p_is_step = 1 THEN
        IF p_step_path IS NULL THEN p_step_path := i.f_name;
        ELSE p_step_path := p_step_path || ' ' || i.f_name;
        END IF;

      END IF;

      -- �������� ���������/���������
      -- ���� ������� ������ - �������, �� ��������� ������
      -- ����� - �������
      IF p_is_step = 0 THEN
        l_object := AddClassifyGroup(
          l_classify_code,
          i.f_level,
          i.f_name,
          NULL,
          p_omp_parent
          );
      ELSE
        -- ��������� ������ ����
        l_object := sq_technological_steps.NEXTVAL;

        -- ������������ ������ ��������
        -- ���� �� ������, �� ��������� ������ ���� ��� ��������
        IF i.f_blob IS NOT NULL THEN
          l_step_text := i.f_blob;
        ELSE
          l_step_text := p_step_path;
        END IF;

        -- ����������� ���� ��������
        -- �� ��������� - "�������"
        CASE
          WHEN i.f_type = 'OIT_Ust' THEN l_step_type := 1;
          WHEN i.f_type = 'OIT_Rab' THEN l_step_type := 2;
          WHEN i.f_type = 'OIT_Contr' THEN l_step_type := 3;
          ELSE l_step_type := 2;
        END CASE;

        -- ����������� ������ � ������������� ��������
        l_group := NULL;
        l_parent_step := NULL;

        -- ���� ������������ ������� - �������, �� �������� ������ � ������
        -- ����� - �������� �������� ����������� ������������
        IF l_is_step = 0 THEN l_group := p_omp_parent;
        ELSE l_parent_step := p_omp_parent;
        END IF;

        -- �������� ��������
        INSERT INTO technological_steps
        (code, name, steptype, steptext, groupcode, texttype, parent_step)
        VALUES
        (l_object, i.f_name, l_step_type, l_step_text, l_group, 0, l_parent_step);

      END IF;

      -- ������� ��������
      p_level := p_level + 1;
      -- ����� �� �������
      p_order := p_order + 1;

      -- �����������
      INSERT INTO sepo_tech_steps_tree
      VALUES
      (i.f_owner, i.f_level, i.f_name, p_is_step, p_path, p_step_path, p_level, p_order, i.f_blob);

      -- ��������
      BuildStepClassify_pvt(
        p_classify,
        i.f_level,
        l_object,
        p_is_step,
        p_path,
        p_step_path,
        p_level,
        p_order
      );

      -- �������� �� ��� �����
      p_is_step := l_is_step;
      p_level := p_level - 1;
      p_step_path := l_step_path;
      p_path := l_path;

    END LOOP;

  END;

  -- ���������� �������������� ������� ������������
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

  -- ��������� �������� ������������� ��������
  PROCEDURE SetOperaionSuffix
  IS
  BEGIN
    -- ���������� ��������
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

    -- �������� � ����������� ��������
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

  -- �������� ��������� �� ��������������� ��������
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
    -- ������� ��� ���������, ������� �� ������� � ������������
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
    -- ��������� ���������, ���� �� ��� � �����������
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
    l_classify_code := GetOperClassifyCode();

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

  PROCEDURE LoadSteps
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
      l_order
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

  PROCEDURE LoadEqpModelCatalogs(p_classify NUMBER)
  IS
  BEGIN
    BuildModelsClassify_pvt(p_classify, 0, NULL);
  END;

  PROCEDURE LoadEqpModels(p_owner NUMBER)
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

END;
/