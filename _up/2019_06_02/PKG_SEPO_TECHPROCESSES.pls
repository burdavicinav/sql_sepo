PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_techprocesses
CREATE OR REPLACE PACKAGE pkg_sepo_techprocesses
AS
  FUNCTION gettptype(p_tpcode NUMBER) RETURN NUMBER;

  FUNCTION gettptypeforoper(p_opercode NUMBER) RETURN NUMBER;

  FUNCTION addoperation (
    p_tpcode NUMBER,
    p_opernum operations_for_techprocesses.opernum%TYPE,
    p_wscode NUMBER,
    p_opercode NUMBER,
    p_remark CLOB,
    p_groupcode NUMBER,
    p_groupextcode NUMBER,
    p_opertype NUMBER,
    p_seccode NUMBER,
    p_dopname VARCHAR2
  )
  RETURN NUMBER;

  FUNCTION linktptoko (
    p_tpcode NUMBER,
    p_tptype NUMBER,
    p_unvcode NUMBER,
    p_ordernum NUMBER
  )
  RETURN NUMBER;

  FUNCTION linkopertoko (
    p_opercode NUMBER,
    p_tptoko NUMBER
  )
  RETURN NUMBER;

  PROCEDURE linkopertoko (
    p_opercode NUMBER
  );

  FUNCTION createtp(
    p_type NUMBER,
    p_sign techprocesses.Sign%TYPE,
    p_name techprocesses.name%TYPE,
    p_dobjcode NUMBER,
    p_groupcode NUMBER,
    p_letter NUMBER,
    p_state NUMBER,
    p_owner NUMBER,
    p_remark CLOB,
    p_wscode NUMBER,
    p_sectioncode NUMBER
  )
  RETURN NUMBER;

  PROCEDURE addinstruction(
    p_opercode NUMBER,
    p_inscode NUMBER,
    p_num NUMBER
  );

  FUNCTION addstep (
    p_opercode NUMBER,
    p_stepcode NUMBER,
    p_stepnum NUMBER,
    p_remark CLOB
  )
  RETURN NUMBER;

  FUNCTION addstep (
    p_opercode NUMBER,
    p_stepname VARCHAR2,
    p_steptype NUMBER,
    p_stepnum VARCHAR2,
    p_steptext CLOB,
    p_remark CLOB,
    p_stepcode NUMBER := NULL
  )
  RETURN NUMBER;

  PROCEDURE linksteptoko (
    p_stepcode NUMBER,
    p_tpoptoko NUMBER
  );

  PROCEDURE addperformeronoper (
    p_opercode NUMBER,
    p_category NUMBER,
    p_profession NUMBER,
    p_count NUMBER,
    p_ordernum NUMBER,
    p_perfcode OUT NUMBER
  );

  PROCEDURE linkperformertoko (
    p_perfcode NUMBER,
    p_tptoko NUMBER
  );

  PROCEDURE linkperformertooperko (
    p_perfcode NUMBER,
    p_tpoptoko NUMBER
  );

  PROCEDURE addperformeronstep (
    p_stepcode NUMBER,
    p_category NUMBER,
    p_profession NUMBER,
    p_count NUMBER,
    p_ordernum NUMBER,
    p_perfcode OUT NUMBER
  );

  PROCEDURE linkstepperformertoko (
    p_perfcode NUMBER,
    p_tptoko NUMBER
  );

  PROCEDURE linkstepperformertooperko (
    p_perfcode NUMBER,
    p_tpsttoko NUMBER
  );

  PROCEDURE addequipmentmodel (
    p_opercode NUMBER,
    p_eqpcode NUMBER,
    p_ordernum NUMBER,
    p_eqpmodel OUT NUMBER
  );

  PROCEDURE linkequipmentmodeltooperko (
    p_tpoptoko NUMBER,
    p_eqpmodel NUMBER
  );

  PROCEDURE addfixtureonoper (
    p_opercode NUMBER,
    p_fixcode NUMBER,
    p_count NUMBER,
    p_norm NUMBER,
    p_ordernum NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE linkfixturetooperko (
    p_fixcode NUMBER,
    p_tpoptoko NUMBER,
    p_count NUMBER,
    p_norm NUMBER
  );

  PROCEDURE addfixtureonstep (
    p_stepcode NUMBER,
    p_fixcode NUMBER,
    p_count NUMBER,
    p_norm NUMBER,
    p_ordernum NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE linkstepfixturetooperko (
    p_fixcode NUMBER,
    p_tpsttoko NUMBER,
    p_count NUMBER,
    p_norm NUMBER
  );

  PROCEDURE addopertimeprops (
    p_opercode NUMBER,
    p_detcount NUMBER,
    p_meascode NUMBER
  );

  PROCEDURE addgroupopertimeprops (
    p_tpoptoko NUMBER,
    p_detcount NUMBER,
    p_meascode NUMBER
  );

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_techprocesses
CREATE OR REPLACE PACKAGE BODY pkg_sepo_techprocesses
AS
  FUNCTION gettptype(p_tpcode NUMBER) RETURN NUMBER
  IS
    l_tptype NUMBER;
  BEGIN
    SELECT TYPE INTO l_tptype FROM techprocesses WHERE code = p_tpcode;

    RETURN l_tptype;

  END;

  FUNCTION gettptypeforoper(p_opercode NUMBER) RETURN NUMBER
  IS
    l_tptype NUMBER;
  BEGIN
    SELECT
      t.TYPE
    INTO
      l_tptype
    FROM
      operations_for_techprocesses o,
      techprocesses t
    WHERE
        o.tech_processes_code = t.code;

    RETURN l_tptype;

  END;

  FUNCTION addoperation (
    p_tpcode NUMBER,
    p_opernum operations_for_techprocesses.opernum%TYPE,
    p_wscode NUMBER,
    p_opercode NUMBER,
    p_remark CLOB,
    p_groupcode NUMBER,
    p_groupextcode NUMBER,
    p_opertype NUMBER,
    p_seccode NUMBER,
    p_dopname VARCHAR2
  )
  RETURN NUMBER
  IS
    l_opercode NUMBER;
    l_rtf CLOB;
  BEGIN
    l_opercode := sq_operations_for_tp.NEXTVAL;
    l_rtf := pkg_sepo_raw_operations.getrtf(p_remark);

    INSERT INTO operations_for_techprocesses (
      code, tech_processes_code, ttp_code, sections_code, ws_code,
      tech_oper_code, opernum, remark, revision, ARCHIVE, begindate,
      enddate, distrgroup, distrgroupext, tp_params_set,
      opertype, tp_link_sign, use_percent, change_block,
      sumupstepstime, usemainmatnorms, addname, note
    )
    VALUES (
      l_opercode, p_tpcode, NULL, p_seccode, p_wscode,
      p_opercode, p_opernum, l_rtf, 0, 0, NULL,
      NULL, p_groupcode, p_groupextcode, NULL,
      p_opertype, NULL, 0, NULL,
      0, 0, p_dopname, NULL
    );

    RETURN l_opercode;

  END;

  FUNCTION linktptoko (
    p_tpcode NUMBER,
    p_tptype NUMBER,
    p_unvcode NUMBER,
    p_ordernum NUMBER
  )
  RETURN NUMBER
  IS
    l_code NUMBER;
  BEGIN
    l_code := sq_techproc_to_kobj.NEXTVAL;

    INSERT INTO techproc_to_kobj (
      code, tpcode, unvcode, district, sortnum, groupcode,
      subgroupcode, TYPE
    )
    VALUES (
      l_code, p_tpcode, p_unvcode, NULL, NULL, NULL,
      NULL, p_tptype
    );

    INSERT INTO techproc_to_kobj_history (
      code, ordernum, changedate
    )
    VALUES (
      l_code, p_ordernum, SYSDATE
    );

    RETURN l_code;

  END;

  FUNCTION linkopertoko (
    p_opercode NUMBER,
    p_tptoko NUMBER
  )
  RETURN NUMBER
  IS
    l_code NUMBER;
  BEGIN
    l_code := sq_techoper_to_kobj.NEXTVAL;

    INSERT INTO techoper_to_kobj (
      code, tptoko, tpopercode
    )
    VALUES (
      l_code, p_tptoko, p_opercode
    );

    RETURN l_code;

  END;

  PROCEDURE linkopertoko (
    p_opercode NUMBER
  )
  IS
    l_code NUMBER;
  BEGIN
    FOR i IN (
      SELECT
        t.code
      FROM
        operations_for_techprocesses o,
        techproc_to_kobj t
      WHERE
          t.tpcode = o.tech_processes_code
        AND
          o.code = p_opercode

    ) LOOP
      l_code := linkopertoko(p_opercode, i.code);

    END LOOP;

  END;

  FUNCTION createtp(
    p_type NUMBER,
    p_sign techprocesses.Sign%TYPE,
    p_name techprocesses.name%TYPE,
    p_dobjcode NUMBER,
    p_groupcode NUMBER,
    p_letter NUMBER,
    p_state NUMBER,
    p_owner NUMBER,
    p_remark CLOB,
    p_wscode NUMBER,
    p_sectioncode NUMBER
    )
  RETURN NUMBER
  IS
    l_prodcode NUMBER;
    l_bocode NUMBER;
    l_tpcode NUMBER;
    l_opercode NUMBER;
    l_prodhistory NUMBER;
    l_promcode NUMBER;
    l_tmpblob BLOB;
  BEGIN
    l_prodcode := sq_production.NEXTVAL;

    INSERT INTO bo_production (
      code, Sign, TYPE
    )
    VALUES (
      l_prodcode, p_sign, 60
    );

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 60, NULL, so.GetNextSoNum()
    );

    pkg_sepo_attr_operations.init(60);
    pkg_sepo_attr_operations.addattr('Учет_по_маршрут', 100);
    pkg_sepo_attr_operations.geninsertsql();
    pkg_sepo_attr_operations.executecommand(l_bocode);

--    l_opercode := addoperation(NULL, '001');
    l_tpcode := sq_techprocesses.NEXTVAL;

    INSERT INTO techprocesses (
      elementki_performers_code, divisionobj_code, sections_code, techproc_code,
      distr_group_code, dobjcode, plantcode, TYPE, code, revision,
      Sign, name, invnum, processing_cipher, letter/*, tpopercode*/, bocode
    )
    VALUES (
      NULL, p_wscode, p_sectioncode, NULL,
      p_groupcode, NULL, NULL, p_type, l_tpcode, 0,
      p_sign, p_name, NULL, NULL, p_letter/*, l_tpcode */, l_bocode
    );

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 60, l_tpcode, p_owner, NULL, p_sign, 0, 0,
      l_prodcode, NULL, p_state, SYSDATE, -2,
      SYSDATE, -2
    );

    l_prodhistory := sq_bo_prod_history.NEXTVAL;

    INSERT INTO bo_production_history (
      code, prodcode, revision, bocode, insertdate, deletedate, action,
      usercode, promcode
    )
    VALUES (
      l_prodhistory, l_prodcode, 0, l_bocode, SYSDATE, NULL, 0,
      -2, NULL
    );

    UPDATE business_objects
    SET
      today_prodbocode = l_bocode,
      today_proddoccode = l_tpcode
    WHERE
        prodcode = l_prodcode;

    UPDATE bo_production
    SET
      today_prodbocode = l_bocode,
      today_proddoccode = l_tpcode
    WHERE
        code = l_prodcode;

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, -2, 'OMP Администратор', SYSDATE, SYSDATE,
      NULL, p_state, NULL, SYSDATE, SYSDATE, 0, 0, NULL, l_promcode
    );

    IF p_remark IS NOT NULL THEN
      Dbms_Lob.createtemporary(l_tmpblob, TRUE);
      pkg_sepo_raw_operations.getrtfblob(p_remark, l_tmpblob);

      INSERT INTO techproc_comment (
        tpcode, remark
      )
      VALUES (
        l_tpcode, l_tmpblob
      );

      Dbms_Lob.freetemporary(l_tmpblob);

    END IF;

    RETURN l_tpcode;

  END;

  PROCEDURE addinstruction(
    p_opercode NUMBER,
    p_inscode NUMBER,
    p_num NUMBER
  )
  IS
  BEGIN
    INSERT INTO techoper_instructions (
      code, oper_code, instruct_code, order_num
    )
    VALUES (
      sq_techoper_instructions.NEXTVAL, p_opercode, p_inscode, p_num
    );

  END;

  FUNCTION addstep (
    p_opercode NUMBER,
    p_stepcode NUMBER,
    p_stepnum NUMBER,
    p_remark CLOB
  )
  RETURN NUMBER
  IS
    l_stepcode NUMBER;
    l_name technological_steps.name%TYPE;
    l_steptype NUMBER;
    l_texttype NUMBER;
    l_steptext technological_steps.steptext%TYPE;
    l_steptext_rtf technological_steps.steptext_rtf%TYPE;
    l_remark_rtf CLOB;
  BEGIN
    SELECT
      name,
      steptype,
      texttype,
      steptext,
      steptext_rtf
    INTO
      l_name,
      l_steptype,
      l_texttype,
      l_steptext,
      l_steptext_rtf
    FROM
      technological_steps
    WHERE
        code = p_stepcode;

    l_remark_rtf := pkg_sepo_raw_operations.getrtf(p_remark);
    l_stepcode := sq_steps_for_operation.NEXTVAL;

    INSERT INTO steps_for_operation (
      code, oper_for_tech_code, tech_steps_code, stepnum, steptext,
      revision, ARCHIVE, begindate, enddate, steptype, name,
      converted, tp_oper_code, texttype, remark, is_copy_control
    )
    VALUES (
      l_stepcode, p_opercode, p_stepcode, p_stepnum, l_steptext,
      0, 0, SYSDATE, NULL, l_steptype, l_name,
      1, p_opercode, l_texttype, l_remark_rtf, 0
    );

    INSERT INTO steps_for_oper_steptext (
      stepcode, steptext_rtf
    )
    VALUES (
      l_stepcode, l_steptext_rtf
    );

    RETURN l_stepcode;

  END;

  FUNCTION addstep (
    p_opercode NUMBER,
    p_stepname VARCHAR2,
    p_steptype NUMBER,
    p_stepnum VARCHAR2,
    p_steptext CLOB,
    p_remark CLOB,
    p_stepcode NUMBER := NULL
  )
  RETURN NUMBER
  IS
    l_stepcode NUMBER;
    l_remark_rtf CLOB;
  BEGIN
    l_remark_rtf := pkg_sepo_raw_operations.getrtf(p_remark);
    l_stepcode := sq_steps_for_operation.NEXTVAL;

    INSERT INTO steps_for_operation (
      code, oper_for_tech_code, tech_steps_code, stepnum, steptext,
      revision, ARCHIVE, begindate, enddate, steptype, name,
      converted, tp_oper_code, texttype, remark, is_copy_control
    )
    VALUES (
      l_stepcode, p_opercode, p_stepcode, p_stepnum, p_steptext,
      0, 0, SYSDATE, NULL, p_steptype, p_stepname,
      1, p_opercode, 0, l_remark_rtf, 0
    );

    INSERT INTO steps_for_oper_steptext (
      stepcode, steptext_rtf
    )
    VALUES (
      l_stepcode, NULL
    );

    RETURN l_stepcode;

  END;

  PROCEDURE linksteptoko (
    p_stepcode NUMBER,
    p_tpoptoko NUMBER
  )
  IS
    l_code NUMBER;
  BEGIN
    l_code := sq_techstep_to_kobj.NEXTVAL;

    INSERT INTO techstep_to_kobj (
      code, tpoptoko, tpstepcode
    )
    VALUES (
      l_code, p_tpoptoko, p_stepcode
    );

  END;

  PROCEDURE addperformeronoper (
    p_opercode NUMBER,
    p_category NUMBER,
    p_profession NUMBER,
    p_count NUMBER,
    p_ordernum NUMBER,
    p_perfcode OUT NUMBER
  )
  IS
    l_bocode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    p_perfcode := sq_tpoper_performers.NEXTVAL;

    INSERT INTO tpoper_performers (
      code, tp_oper_code, category, profession, paytime,
      performertime, timemeas, socode, production_kind,
      price_kind, wage_rate_code, performer_count, ordernum, cost
    )
    VALUES (
      p_perfcode, p_opercode, p_category, p_profession, 0,
      0, NULL, l_bocode, NULL,
      NULL, NULL, p_count, p_ordernum, 0
    );

  END;

  PROCEDURE linkperformertoko (
    p_perfcode NUMBER,
    p_tptoko NUMBER
  )
  IS
    l_bocode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    INSERT INTO tptoko_performers (
      socode, tptoko_code, performer_code
    )
    VALUES (
      l_bocode, p_tptoko, p_perfcode
    );

  END;

  PROCEDURE linkperformertooperko (
    p_perfcode NUMBER,
    p_tpoptoko NUMBER
  )
  IS
    l_bocode NUMBER;
    l_opercode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    INSERT INTO tpoptoko_performers (
      socode, tpoptoko_code, performer_code
    )
    VALUES (
      l_bocode, p_tpoptoko, p_perfcode
    );

  END;

  PROCEDURE addperformeronstep (
    p_stepcode NUMBER,
    p_category NUMBER,
    p_profession NUMBER,
    p_count NUMBER,
    p_ordernum NUMBER,
    p_perfcode OUT NUMBER
  )
  IS
    l_opercode NUMBER;
    l_bocode NUMBER;
    l_perfcode NUMBER;
    l_perfcount NUMBER;
    l_tptype NUMBER;
  BEGIN
    SELECT
      tp_oper_code
    INTO
      l_opercode
    FROM
      steps_for_operation
    WHERE
        code = p_stepcode;

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    l_perfcode := sq_tpstep_performers.NEXTVAL;

    INSERT INTO tpstep_performers (
      code, socode, tp_step_code, category, profession, paytime,
      performertime, timemeas, wage_rate_code, performer_count, ordernum, cost
    )
    VALUES (
      l_perfcode, l_bocode, p_stepcode, p_category, p_profession, 0,
      0, NULL, NULL, p_count, p_ordernum, 0
    );

    SELECT
      Count(1)
    INTO
      l_perfcount
    FROM
      tpoper_performers
    WHERE
        tp_oper_code = l_opercode
      AND
        category = p_category
      AND
        profession = p_profession;

    p_perfcode := l_perfcode;

    IF l_perfcount = 0 THEN
      addperformeronoper(
        l_opercode,
        p_category,
        p_profession,
        p_count,
        p_ordernum,
        l_perfcode
      );

--      l_tptype := gettptypeforoper(l_opercode);

    END IF;

  END;

  PROCEDURE linkstepperformertoko (
    p_perfcode NUMBER,
    p_tptoko NUMBER
  )
  IS
    l_bocode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    INSERT INTO tptoko_step_performers (
      socode, tptoko_code, performer_code
    )
    VALUES (
      l_bocode, p_tptoko, p_perfcode
    );

  END;

  PROCEDURE linkstepperformertooperko (
    p_perfcode NUMBER,
    p_tpsttoko NUMBER
  )
  IS
    l_bocode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 1000034, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_1000034 (socode) VALUES (l_bocode);

    INSERT INTO tpsttoko_performers (
      socode, tpsttoko_code, performer_code
    )
    VALUES (
      l_bocode, p_tpsttoko, p_perfcode
    );

  END;

  PROCEDURE addequipmentmodel (
    p_opercode NUMBER,
    p_eqpcode NUMBER,
    p_ordernum NUMBER,
    p_eqpmodel OUT NUMBER
  )
  IS
    l_code NUMBER;
  BEGIN
    l_code := sq_eqp_model_to_techprocoper.NEXTVAL;

    INSERT INTO eqp_model_to_techprocoper (
      techprocoper, eqpmodel, code, tp_oper_code, ordernum
    )
    VALUES (
      p_opercode, p_eqpcode, l_code, p_opercode, p_ordernum
    );

    p_eqpmodel := l_code;

  END;

  PROCEDURE linkequipmentmodeltooperko (
    p_tpoptoko NUMBER,
    p_eqpmodel NUMBER
  )
  IS
  BEGIN
    INSERT INTO tpoptoko_to_eqpmodel (
      tpoptoko, eqpmodel
    )
    VALUES (
      p_tpoptoko, p_eqpmodel
    );

  END;

  PROCEDURE addfixtureonoper (
    p_opercode NUMBER,
    p_fixcode NUMBER,
    p_count NUMBER,
    p_norm NUMBER,
    p_ordernum NUMBER,
    p_code OUT NUMBER
  )
  IS
  BEGIN
    p_code := sq_fixture_to_operation.NEXTVAL;

    INSERT INTO fixture_to_operation (
      code, oper_for_tech_code, fixture_base_code, Count, countmeas,
      norm, tp_oper_code, mainfixture, ordernum
    )
    VALUES (
      p_code, p_opercode, p_fixcode, p_count, 106,
      p_norm, p_opercode, 1, p_ordernum
    );

  END;

  PROCEDURE linkfixturetooperko (
    p_fixcode NUMBER,
    p_tpoptoko NUMBER,
    p_count NUMBER,
    p_norm NUMBER
  )
  IS
  BEGIN
    INSERT INTO tpoptoko_to_fixture (
      tpoptoko, fixture, Count, countmeas, norm
    )
    VALUES (
      p_tpoptoko, p_fixcode, p_count, 106, p_norm
    );

  END;

  PROCEDURE addfixtureonstep (
    p_stepcode NUMBER,
    p_fixcode NUMBER,
    p_count NUMBER,
    p_norm NUMBER,
    p_ordernum NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_fixcode NUMBER;
    l_opercode NUMBER;
    l_fixexists NUMBER;
    l_code NUMBER;
  BEGIN
    SELECT
      tp_oper_code
    INTO
      l_opercode
    FROM
      steps_for_operation
    WHERE
        code = p_stepcode;

    l_fixcode := sq_fixture_to_step.NEXTVAL;

    INSERT INTO fixture_to_step (
      code, fixture_base_code, st_for_oper_code, Count, countmeas,
      norm, tp_step_code, mainfixture, ordernum
    )
    VALUES (
      l_fixcode, p_fixcode, p_stepcode, p_count, 106,
      p_norm, p_stepcode, 1, p_ordernum
    );

    SELECT
      Count(1)
    INTO
      l_fixexists
    FROM
      fixture_to_operation
    WHERE
        oper_for_tech_code = l_opercode
      AND
        fixture_base_code = p_fixcode;

    p_code := l_fixcode;

    IF l_fixexists = 0 THEN
      pkg_sepo_techprocesses.addfixtureonoper (
        l_opercode,
        p_fixcode,
        p_count,
        p_norm,
        p_ordernum,
        l_code
      );

    END IF;

  END;

  PROCEDURE linkstepfixturetooperko (
    p_fixcode NUMBER,
    p_tpsttoko NUMBER,
    p_count NUMBER,
    p_norm NUMBER
  )
  IS
    l_fixbasecode NUMBER;
    l_tpoptoko NUMBER;
    l_operation NUMBER;
    l_exists NUMBER;
    l_fixopercode NUMBER;
  BEGIN
    INSERT INTO tpsttoko_to_fixture (
      tpsttoko, fixture, Count, countmeas
    )
    VALUES (
      p_tpsttoko, p_fixcode, p_count, 106
    );

    -- далее проверка на связь оснастки на операции c КД
    -- если не связана, то связать

    SELECT
      fixture_base_code
    INTO
      l_fixbasecode
    FROM
      fixture_to_step
    WHERE
        code = p_fixcode;

    SELECT
      s.tpoptoko,
      o.tpopercode
    INTO
      l_tpoptoko,
      l_operation
    FROM
      techstep_to_kobj s,
      techoper_to_kobj o
    WHERE
        s.code = p_tpsttoko
      AND
        o.code = s.tpoptoko;

    SELECT
      Count(1)
    INTO
      l_exists
    FROM
      tpoptoko_to_fixture f,
      fixture_to_operation o
    WHERE
        o.code = f.fixture
      AND
        f.tpoptoko = l_tpoptoko
      AND
        o.fixture_base_code = l_fixbasecode;

    IF l_exists = 0 THEN
      SELECT
        code
      INTO
        l_fixopercode
      FROM
        fixture_to_operation
      WHERE
          fixture_base_code = l_fixbasecode
        AND
          oper_for_tech_code = l_operation;

      linkfixturetooperko(l_fixopercode, l_tpoptoko, p_count, p_norm);

    END IF;

  END;

  PROCEDURE addopertimeprops (
    p_opercode NUMBER,
    p_detcount NUMBER,
    p_meascode NUMBER
  )
  IS
    l_bocode NUMBER;
  BEGIN
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, num
    )
    VALUES (
      l_bocode, 1000033, so.getnextsonum()
    );

    pkg_sepo_attr_operations.init(1000033);

    pkg_sepo_attr_operations.addattr('КОИД', p_detcount);
    pkg_sepo_attr_operations.geninsertsql();
    pkg_sepo_attr_operations.executecommand(l_bocode);

    INSERT INTO tpoper_time_rates (
      socode, tpopercode
    )
    VALUES (
      l_bocode, p_opercode
    );

    INSERT INTO techoperation_time_rates (
      oper_for_tech_code, work_aux_time_units, batchtime_units, koid
    )
    VALUES (
      p_opercode, p_meascode, p_meascode, p_detcount
    );

  END;

  PROCEDURE addgroupopertimeprops (
    p_tpoptoko NUMBER,
    p_detcount NUMBER,
    p_meascode NUMBER
  )
  IS
    l_bocode NUMBER;
    l_operation NUMBER;
  BEGIN
    SELECT
      tpopercode
    INTO
      l_operation
    FROM
      techoper_to_kobj
    WHERE
        code = p_tpoptoko;

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, num
    )
    VALUES (
      l_bocode, 1000033, so.getnextsonum()
    );

    pkg_sepo_attr_operations.init(1000033);

    pkg_sepo_attr_operations.addattr('КОИД', p_detcount);
    pkg_sepo_attr_operations.geninsertsql();
    pkg_sepo_attr_operations.executecommand(l_bocode);

    INSERT INTO tpoptoko_time_rates (
      socode, tpoptokocode
    )
    VALUES (
      l_bocode, p_tpoptoko
    );

    INSERT INTO tpoper_to_ko_time_rates (
      oper_for_tech_code, tpoptokocode, work_aux_time_units, batchtime_units,
      koid
    )
    VALUES (
      l_operation, p_tpoptoko, p_meascode, p_meascode, p_detcount
    );

  END;

END;
/

