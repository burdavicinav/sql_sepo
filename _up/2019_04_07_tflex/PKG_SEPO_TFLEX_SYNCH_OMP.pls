PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_tflex_synch_omp
CREATE OR REPLACE PACKAGE pkg_sepo_tflex_synch_omp
AS
  PROCEDURE altapply(p_str IN OUT VARCHAR2);

  PROCEDURE create_spec_fix (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_fixtype NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE create_fixture (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_fixtype NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE create_detail (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE add_file (
    p_code NUMBER,
    p_fname VARCHAR2,
    p_fhash VARCHAR2,
    p_file BLOB,
    p_user NUMBER,
    p_groupcode NUMBER,
    p_linkdoccode NUMBER,
    p_doccode OUT NUMBER
  );

  PROCEDURE clear_specification (
    p_spc NUMBER
  );

  PROCEDURE add_element (
    p_spc NUMBER,
    p_elem NUMBER,
    p_type NUMBER,
    p_section NUMBER,
    p_cnt NUMBER,
    p_position VARCHAR2,
    p_user NUMBER
  );

  PROCEDURE create_spec_draw (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  );

  PROCEDURE create_document (
    p_doctype NUMBER,
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  );

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY pkg_sepo_tflex_synch_omp
CREATE OR REPLACE PACKAGE BODY pkg_sepo_tflex_synch_omp
AS
  -- применение alt-символов
  PROCEDURE altapply(p_str IN OUT VARCHAR2)
  IS
    l_position NUMBER := 0;
    l_alt VARCHAR2(10);
    l_alt_value VARCHAR2(100);
  BEGIN
    LOOP
      l_position := l_position + 1;
      l_alt := regexp_substr(p_str, '%%(\d{3}|\w|-)', 1, l_position);

      IF l_alt IS NULL THEN EXIT; END IF;

      SELECT
        Max(value_)
      INTO
        l_alt_value
      FROM
        sepo_tflex_alt_code_list
      WHERE
          code = REPLACE(l_alt, '%', '');

      IF l_alt_value IS NOT NULL THEN
        p_str := REPLACE(p_str, l_alt, l_alt_value);
        l_position := l_position - 1;

      END IF;

    END LOOP;

  END;

  -- увеличивает обозначение ревизии на единицу
  PROCEDURE increvsign(p_value IN OUT VARCHAR2)
  IS
    l_decimal VARCHAR2(10) := '0123456789';
    l_rusupchar VARCHAR2(31) := 'АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
    l_engupchar VARCHAR2(26) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    l_ruslwchar VARCHAR2(31) := Lower(l_rusupchar);
    l_englwchar VARCHAR2(26) := Lower(l_engupchar);

    i INTEGER;
    l_char CHAR;
    l_currentdict VARCHAR2(31);
    l_index INTEGER;
    up_index INTEGER := 1;
    l_nextvalue VARCHAR2(101);
  BEGIN
    i := Length(p_value);

    WHILE i > 0 LOOP

      l_currentdict := '';
      l_char := SubStr(p_value, i, 1);

      IF up_index = 1 THEN
        IF InStr(l_decimal, l_char) > 0 THEN
          l_currentdict := l_decimal;

        ELSIF InStr(l_rusupchar, l_char) > 0 THEN
          l_currentdict := l_rusupchar;

        ELSIF InStr(l_ruslwchar, l_char) > 0 THEN
          l_currentdict := l_ruslwchar;

        ELSIF InStr(l_engupchar, l_char) > 0 THEN
          l_currentdict := l_engupchar;

        ELSIF InStr(l_englwchar, l_char) > 0 THEN
          l_currentdict := l_englwchar;

        END IF;

        IF l_currentdict IS NULL THEN
          up_index := 0;

        ELSE
          l_index := InStr(l_currentdict, l_char);

          IF l_index + 1 > Length(l_currentdict) THEN
            l_char := SubStr(l_currentdict, 1, 1);

          ELSE
            l_char := SubStr(l_currentdict, l_index + 1, 1);
            up_index := 0;

          END IF;

        END IF;

      END IF;

      l_nextvalue := l_char || l_nextvalue;

      i := i - 1;

    END LOOP;

    IF l_nextvalue IS NOT NULL THEN
      IF up_index = 1 THEN l_nextvalue := '1' || l_nextvalue; END IF;

    END IF;

    p_value := l_nextvalue;

  END;

  PROCEDURE set_approval_scheme(
    p_botype NUMBER,
    p_bostate NUMBER,
    p_owner NUMBER,
    p_bocode NUMBER
  )
  IS

  BEGIN
    FOR i IN (
      SELECT
        o.code AS operation,
        s.code AS scheme
      FROM
        businessobj_operations o
        JOIN
        bo_opers_approval_schemes s
        ON
            s.operation = o.code
        JOIN
        bo_params pr
        ON
            pr.code = s.param
        left JOIN
        bo_param_values prv
        ON
            prv.param = pr.code
      WHERE
          pr.param_type IN (0,7)
        AND
          botype = p_botype
        AND
          current_state = p_bostate
        AND
          coalesce(
            To_Number(regexp_replace(prv.Value, '^.*!\*\*!(\d+)$', '\1')),
            p_owner) = p_owner

    ) LOOP
      INSERT INTO bo_operation_scheme (
        bocode, operation, scheme
      )
      VALUES (
        p_bocode, i.operation, i.scheme
      );

      FOR j IN (
        WITH f(code) AS
        (
          SELECT
            ap.code
          FROM
            bo_opers_approval ap
          WHERE
              ap.scheme = i.scheme
            AND
              NOT EXISTS (
                SELECT
                  1
                FROM
                  bo_opers_approval_previous pr
                WHERE
                    pr.approval = ap.code
                  AND
                    pr.delete_date IS NULL
              )

          UNION ALL

          SELECT
            pr.approval
          FROM
            bo_opers_approval_previous pr
            JOIN
            f
            ON
                pr.previous = f.code
              AND
                pr.delete_date IS NULL
        )
        search depth first BY code SET orderval
        SELECT
          ap.code,
          ap.ismandatory
        FROM
          f
          JOIN
          bo_opers_approval ap
          ON
              ap.code = f.code
        ORDER BY
          orderval

      ) LOOP

        INSERT INTO bo_opers_approval_history (
          code, businessobj, approval, signed, lastname, donedate,
          rdate, iscurrent, ismandatory, hist_date, is_in_use
        )
        VALUES (
          sq_booapprovalhist_code.NEXTVAL, p_bocode, j.code, 0, ' ', SYSDATE,
          SYSDATE, 1, j.ismandatory, SYSDATE, 1
        );

      END LOOP;

    END LOOP;

  END;

  PROCEDURE create_spec_fix (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_fixtype NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_bosign bo_production.Sign%TYPE;
    l_newobj BOOLEAN;
    l_bpcode NUMBER;
    l_bocode NUMBER;
    l_kocode NUMBER;
    l_bphistcode NUMBER;
    l_promcode NUMBER;
    l_revision NUMBER;
    l_meascode NUMBER;
    l_username user_list.fullname%TYPE;
    l_date DATE := SYSDATE;
    l_revsign business_objects.revsign%TYPE;
    l_name konstrobj.name%TYPE;
  BEGIN
    -- поиск обозначения по оригинальному обозначению
    SELECT
      Max(k.Sign)
    INTO
      l_bosign
    FROM
      fixture_base fb
      JOIN
      konstrobj k
      ON
          k.unvcode = fb.code
    WHERE
        originalname = p_sign;

    -- если обозначение БО не найдено, то обозначение БО приравнивается
    -- к обозначение ориг
    l_bosign := Nvl(l_bosign, p_sign);

    -- если объект на указанном статусе уже существует...
    SELECT
      Max(b.doccode)
    INTO
      l_kocode
    FROM
      fixture_base fb
      JOIN
      business_objects b
      ON
          b.doccode = fb.code
    WHERE
        b.TYPE = 31
      AND
        b.today_state = p_state
      AND
        b.name = l_bosign;

    -- то объект не создается
    IF l_kocode IS NOT NULL THEN
      p_code := l_kocode;
      RETURN;

    END IF;

    -- иначе, определить номер ревизии
    SELECT
      Max(revision)
    INTO
      l_revision
    FROM
      konstrobj
    WHERE
        itemtype = 31
      AND
        Sign = l_bosign;

    -- если есть хотя бы одна ревизия
    IF l_revision IS NOT NULL THEN

      -- то выбрать сквозной код объекта
      SELECT
        prodcode,
        revsign
      INTO
        l_bpcode,
        l_revsign
      FROM
        business_objects
      WHERE
          TYPE = 31
        AND
          name = l_bosign
        AND
          revision = l_revision;

      l_newobj := FALSE;

    ELSE
      -- иначе создать новый
      l_bpcode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bpcode, l_bosign, 31
      );

      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bocode, 1000090, NULL, so.getnextsonum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bocode
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_bpcode, l_bocode
      );

      l_newobj := TRUE;

    END IF;

    -- номер ревизии
    l_revision := Nvl(l_revision, -1) + 1;

    -- обозначение ревизии
    -- если у старой ревизии оно заполнено, то увеличивается на 1
    -- иначе приравнивается к номеру ревизии
    IF l_revsign IS NOT NULL THEN
      increvsign(l_revsign);

    ELSE
      l_revsign := To_Char(l_revision);

    END IF;

    -- ФИО пользователя
    SELECT
      fullname
    INTO
      l_username
    FROM
      user_list
    WHERE
        code = p_user;

    -- единицы измерения "ШТ."
    SELECT
      code
    INTO
      l_meascode
    FROM
      measures
    WHERE
        name = 'Штука';

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 31, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_31 (socode) VALUES (l_bocode);

    l_kocode := sq_unvcode.NEXTVAL;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 31, l_kocode, p_owner, NULL, l_bosign, l_revision, l_revsign,
      l_bpcode, NULL, p_state, l_date, p_user,
      l_date, p_user
    );

    IF l_newobj THEN

      l_bphistcode := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode
      )
      VALUES (
        l_bphistcode, l_bpcode, l_revision, l_bocode, l_date, NULL, 0,
        p_user, NULL
      );

    END IF;

    -- применение alt кодов
    l_name := p_name;
    altapply(l_name);

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 31, l_bocode, 0, l_bosign, l_name, NULL, 1,
      NULL, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    INSERT INTO fixture_base (
      code, kotype, fixture_types_code, originalname
      )
    VALUES (
      l_kocode, 31, p_fixtype, p_sign
    );

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, l_date, l_date,
      NULL, p_state, NULL, l_date, l_date, 0,
      l_revision, NULL, l_promcode
    );

    set_approval_scheme(31, p_state, p_owner, l_bocode);

    p_code := l_kocode;

  END;

  PROCEDURE create_fixture (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_fixtype NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_bosign bo_production.Sign%TYPE;
    l_newobj BOOLEAN;
    l_bpcode NUMBER;
    l_bocode NUMBER;
    l_kocode NUMBER;
    l_bphistcode NUMBER;
    l_promcode NUMBER;
    l_revision NUMBER;
    l_meascode NUMBER;
    l_username user_list.fullname%TYPE;
    l_date DATE := SYSDATE;
    l_revsign business_objects.revsign%TYPE;
    l_name konstrobj.name%TYPE;
  BEGIN
    -- поиск обозначения по оригинальному обозначению
    SELECT
      Max(k.Sign)
    INTO
      l_bosign
    FROM
      fixture_base fb
      JOIN
      konstrobj k
      ON
          k.unvcode = fb.code
    WHERE
        originalname = p_sign;

    -- если обозначение БО не найдено, то обозначение БО приравнивается
    -- к обозначение ориг
    l_bosign := Nvl(l_bosign, p_sign);

    -- если объект на указанном статусе уже существует...
    SELECT
      Max(b.doccode)
    INTO
      l_kocode
    FROM
      fixture_base fb
      JOIN
      business_objects b
      ON
          b.doccode = fb.code
    WHERE
        b.TYPE = 32
      AND
        b.today_state = p_state
      AND
        b.name = l_bosign;

    -- то объект не создается
    IF l_kocode IS NOT NULL THEN
      p_code := l_kocode;
      RETURN;

    END IF;

    -- иначе, определить номер ревизии
    SELECT
      Max(revision)
    INTO
      l_revision
    FROM
      konstrobj
    WHERE
        itemtype = 32
      AND
        Sign = l_bosign;

    -- если есть хотя бы одна ревизия
    IF l_revision IS NOT NULL THEN

      -- то выбрать сквозной код объекта
      SELECT
        prodcode,
        revsign
      INTO
        l_bpcode,
        l_revsign
      FROM
        business_objects
      WHERE
          TYPE = 32
        AND
          name = l_bosign
        AND
          revision = l_revision;

      l_newobj := FALSE;

    ELSE
      -- иначе создать новый
      l_bpcode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bpcode, l_bosign, 32
      );

      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bocode, 1000090, NULL, so.getnextsonum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bocode
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_bpcode, l_bocode
      );

      l_newobj := TRUE;

    END IF;

    -- номер ревизии
    l_revision := Nvl(l_revision, -1) + 1;

    -- обозначение ревизии
    -- если у старой ревизии оно заполнено, то увеличивается на 1
    -- иначе приравнивается к номеру ревизии
    IF l_revsign IS NOT NULL THEN
      increvsign(l_revsign);

    ELSE
      l_revsign := To_Char(l_revision);

    END IF;

    -- ФИО пользователя
    SELECT
      fullname
    INTO
      l_username
    FROM
      user_list
    WHERE
        code = p_user;

    -- единицы измерения "ШТ."
    SELECT
      code
    INTO
      l_meascode
    FROM
      measures
    WHERE
        name = 'Штука';

    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 32, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_32 (socode) VALUES (l_bocode);

    l_kocode := sq_unvcode.NEXTVAL;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 32, l_kocode, p_owner, NULL, l_bosign, l_revision, l_revsign,
      l_bpcode, NULL, p_state, l_date, p_user,
      l_date, p_user
    );

    IF l_newobj THEN

      l_bphistcode := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode
      )
      VALUES (
        l_bphistcode, l_bpcode, l_revision, l_bocode, l_date, NULL, 0,
        p_user, NULL
      );

    END IF;

    -- применение alt кодов
    l_name := p_name;
    altapply(l_name);

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 32, l_bocode, 0, l_bosign, l_name, NULL, -1,
      NULL, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    INSERT INTO fixture_base (
      code, kotype, fixture_types_code, originalname
      )
    VALUES (
      l_kocode, 32, p_fixtype, p_sign
    );

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, l_date, l_date,
      NULL, p_state, NULL, l_date, l_date, 0,
      l_revision, NULL, l_promcode
    );

    set_approval_scheme(32, p_state, p_owner, l_bocode);

    p_code := l_kocode;

  END;

  PROCEDURE create_detail (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_newobj BOOLEAN;
    l_bpcode NUMBER;
    l_bocode NUMBER;
    l_kocode NUMBER;
    l_bphistcode NUMBER;
    l_promcode NUMBER;
    l_revision NUMBER;
    l_meascode NUMBER;
    l_username user_list.fullname%TYPE;
    l_date DATE := SYSDATE;
    l_revsign business_objects.revsign%TYPE;
    l_name konstrobj.name%TYPE;
  BEGIN
    -- если объект на указанном статусе уже существует...
    SELECT
      Max(doccode)
    INTO
      l_kocode
    FROM
      business_objects
    WHERE
        TYPE = 2
      AND
        today_state = p_state
      AND
        name = p_sign;

    -- то объект не создается
    IF l_kocode IS NOT NULL THEN
      p_code := l_kocode;
      RETURN;

    END IF;

    -- иначе, определить номер ревизии
    SELECT
      Max(revision)
    INTO
      l_revision
    FROM
      konstrobj
    WHERE
        itemtype = 2
      AND
        Sign = p_sign;

    -- если есть хотя бы одна ревизия
    IF l_revision IS NOT NULL THEN
      -- то выбрать сквозной код объекта
      SELECT
        prodcode,
        revsign
      INTO
        l_bpcode,
        l_revsign
      FROM
        business_objects
      WHERE
          TYPE = 2
        AND
          name = p_sign
        AND
          revision = l_revision;

      l_newobj := FALSE;

    ELSE
      -- иначе создать новый
      l_bpcode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bpcode, p_sign, 2
      );

      l_newobj := TRUE;
      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bocode, 1000090, NULL, so.getnextsonum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bocode
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_bpcode, l_bocode
      );

    END IF;

    -- номер ревизии
    l_revision := Nvl(l_revision, -1) + 1;

    -- обозначение ревизии
    -- если у старой ревизии оно заполнено, то увеличивается на 1
    -- иначе приравнивается к номеру ревизии
    IF l_revsign IS NOT NULL THEN
      increvsign(l_revsign);

    ELSE
      l_revsign := To_Char(l_revision);

    END IF;

    -- ФИО пользователя
    SELECT
      fullname
    INTO
      l_username
    FROM
      user_list
    WHERE
        code = p_user;

    -- единицы измерения "ШТ."
    SELECT
      code
    INTO
      l_meascode
    FROM
      measures
    WHERE
        name = 'Штука';

    -- создание бизнес-объекта
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 2, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_2 (socode) VALUES (l_bocode);

    l_kocode := sq_unvcode.NEXTVAL;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 2, l_kocode, p_owner, NULL, p_sign, l_revision, l_revsign,
      l_bpcode, NULL, p_state, l_date, p_user,
      l_date, p_user
    );

    IF l_newobj THEN
      l_bphistcode := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode
      )
      VALUES (
        l_bphistcode, l_bpcode, l_revision, l_bocode, l_date, NULL, 0,
        p_user, NULL
      );

    END IF;

    -- применение alt кодов
    l_name := p_name;
    altapply(l_name);

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 2, l_bocode, 0, p_sign, l_name, NULL, -1,
      NULL, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, l_date, l_date,
      NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_promcode
    );

    set_approval_scheme(2, p_state, p_owner, l_bocode);

    p_code := l_kocode;

  END;

  PROCEDURE add_file (
    p_code NUMBER,
    p_fname VARCHAR2,
    p_fhash VARCHAR2,
    p_file BLOB,
    p_user NUMBER,
    p_groupcode NUMBER,
    p_linkdoccode NUMBER,
    p_doccode OUT NUMBER
  )
  IS
    l_bocode NUMBER;
    l_doc NUMBER;
    l_date DATE;
    l_cnt NUMBER;
  BEGIN
    -- загружать только .grb файлы
    IF NOT regexp_like(Lower(p_fname), '\.grb$') THEN RETURN; END IF;

    l_date := SYSDATE;

    SELECT
      bocode
    INTO
      l_bocode
    FROM
      konstrobj
    WHERE
        unvcode = p_code;

--    SELECT
--      Max(code)
--    INTO
--      l_doc
--    FROM
--      documents_params
--    WHERE
--        Lower(name) = Lower(p_fname)
--      AND
--        Lower(HASH) = Lower(p_fhash);

--    IF l_doc IS NULL THEN
      l_doc := sq_documents_code.NEXTVAL;

      INSERT INTO documents (
        code
      )
      VALUES (
        l_doc
      );

      INSERT INTO documents_parts (
        code, num, data
      )
      VALUES (
        l_doc, 1, p_file
      );

      INSERT INTO documents_params (
        code, name, filename, moddate, rdate, f_credate, f_moddate,
        HASH, hash_alg, verdate, usercode
      )
      VALUES (
        l_doc, p_fname, p_fname, l_date, l_date, l_date, l_date,
        p_fhash, 1, l_date, p_user
      );

--    END IF;

    DELETE FROM attachments a_
    WHERE
        a_.code IN (
          SELECT
            a.code
          FROM
            attachments a
            JOIN
            documents_params p
            ON
                p.code = a.document
          WHERE
              a.businessobj = l_bocode
            AND
              Lower(p.filename) = Lower(p_fname)
        );

      INSERT INTO attachments (
        code, businessobj, document, groupcode, hint,
        additional_to
      )
      VALUES (
        sq_attachments_code.NEXTVAL, l_bocode, l_doc, p_groupcode, 0,
        p_linkdoccode
      );

    p_doccode := l_doc;

  END;

  PROCEDURE clear_specification (
    p_spc NUMBER
  )
  IS
  BEGIN
    DELETE FROM specifications WHERE spccode = p_spc;
  END;

  PROCEDURE add_element (
    p_spc NUMBER,
    p_elem NUMBER,
    p_type NUMBER,
    p_section NUMBER,
    p_cnt NUMBER,
    p_position VARCHAR2,
    p_user NUMBER
  )
  IS
    l_bocode NUMBER;
    l_pkey NUMBER;
    l_meascode NUMBER;
  BEGIN

    SELECT
      Max(pkey)
    INTO
      l_pkey
    FROM
      specifications
    WHERE
        spccode = p_spc
      AND
        code = p_elem
      AND
        SECTION = p_type
      AND
        coalesce(position, '0') = coalesce(p_position, '0');

    IF l_pkey IS NOT NULL THEN
      UPDATE specifications SET cntnum = cntnum + p_cnt WHERE pkey = l_pkey;

    ELSE
      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, num
      )
      VALUES (
        l_bocode, 2000031, so.getNextSoNum()
      );

      INSERT INTO obj_attr_values_2000031 (
        socode
      )
      VALUES (
        l_bocode
      );

      -- единицы измерения "ШТ."
      SELECT
        code
      INTO
        l_meascode
      FROM
        measures
      WHERE
          name = 'Штука';

      l_pkey := sq_specifications.NEXTVAL;

      INSERT INTO specifications (
        pkey, rowcode, usercode, spccode, code, SECTION, cntnum,
        meascode, position, sectcode, insertdate
      )
      VALUES (
        l_pkey, l_bocode, p_user, p_spc, p_elem, p_type, p_cnt,
        l_meascode, p_position, p_section, SYSDATE
      );

    END IF;

  END;

  PROCEDURE create_spec_draw (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_newobj BOOLEAN;
    l_bpcode NUMBER;
    l_bocode NUMBER;
    l_kocode NUMBER;
    l_bphistcode NUMBER;
    l_promcode NUMBER;
    l_revision NUMBER;
    l_kind NUMBER;
    l_meascode NUMBER;
    l_username user_list.fullname%TYPE;
    l_date DATE := SYSDATE;
    l_revsign business_objects.revsign%TYPE;
    l_name konstrobj.name%TYPE;
  BEGIN
    -- если объект на указанном статусе уже существует...
    SELECT
      Max(doccode)
    INTO
      l_kocode
    FROM
      business_objects
    WHERE
        TYPE = 6
      AND
        today_state = p_state
      AND
        name = p_sign;

    -- то объект не создается
    IF l_kocode IS NOT NULL THEN
      p_code := l_kocode;
      RETURN;

    END IF;

    -- иначе, определить номер ревизии
    SELECT
      Max(revision)
    INTO
      l_revision
    FROM
      konstrobj
    WHERE
        itemtype = 6
      AND
        Sign = p_sign;

    -- если есть хотя бы одна ревизия
    IF l_revision IS NOT NULL THEN
      -- то выбрать сквозной код объекта
      SELECT
        prodcode,
        revsign
      INTO
        l_bpcode,
        l_revsign
      FROM
        business_objects
      WHERE
          TYPE = 6
        AND
          name = p_sign
        AND
          revision = l_revision;

      l_newobj := FALSE;

    ELSE
      -- иначе создать новый
      l_bpcode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bpcode, p_sign, 6
      );

      l_newobj := TRUE;
      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bocode, 1000090, NULL, so.getnextsonum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bocode
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_bpcode, l_bocode
      );

    END IF;

    -- номер ревизии
    l_revision := Nvl(l_revision, -1) + 1;

    -- обозначение ревизии
    -- если у старой ревизии оно заполнено, то увеличивается на 1
    -- иначе приравнивается к номеру ревизии
    IF l_revsign IS NOT NULL THEN
      increvsign(l_revsign);

    ELSE
      l_revsign := To_Char(l_revision);

    END IF;

    -- ФИО пользователя
    SELECT
      fullname
    INTO
      l_username
    FROM
      user_list
    WHERE
        code = p_user;

    -- единицы измерения "ШТ."
    SELECT
      code
    INTO
      l_meascode
    FROM
      measures
    WHERE
        name = 'Штука';

    -- вид документа
    SELECT
      code
    INTO
      l_kind
    FROM
      ko_documents_kinds
    WHERE
        botype  = 6;

    -- создание бизнес-объекта
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, 6, NULL, so.getnextsonum()
    );

    INSERT INTO obj_attr_values_6 (socode) VALUES (l_bocode);

    l_kocode := sq_unvcode.NEXTVAL;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, 6, l_kocode, p_owner, NULL, p_sign, l_revision, l_revsign,
      l_bpcode, NULL, p_state, l_date, p_user,
      l_date, p_user
    );

    IF l_newobj THEN
      l_bphistcode := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode
      )
      VALUES (
        l_bphistcode, l_bpcode, l_revision, l_bocode, l_date, NULL, 0,
        p_user, NULL
      );

    END IF;

    -- применение alt кодов
    l_name := p_name;
    altapply(l_name);

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 6, l_bocode, 0, p_sign, l_name, NULL, -1,
      l_kind, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, l_date, l_date,
      NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_promcode
    );

    set_approval_scheme(6, p_state, p_owner, l_bocode);

    p_code := l_kocode;

  END;

  PROCEDURE create_document (
    p_doctype NUMBER,
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
    p_code OUT NUMBER
  )
  IS
    l_kotype NUMBER;
    l_koattr NUMBER;
    l_newobj BOOLEAN;
    l_bpcode NUMBER;
    l_bocode NUMBER;
    l_kocode NUMBER;
    l_bphistcode NUMBER;
    l_promcode NUMBER;
    l_revision NUMBER;
    l_kind NUMBER;
    l_meascode NUMBER;
    l_username user_list.fullname%TYPE;
    l_date DATE := SYSDATE;
    l_revsign business_objects.revsign%TYPE;
    l_name konstrobj.name%TYPE;
  BEGIN
    SELECT
      kotype,
      attr
    INTO
      l_kotype,
      l_koattr
    FROM
      kotype_to_botype
    WHERE
        botype = p_doctype;

    -- если объект на указанном статусе уже существует...
    SELECT
      Max(doccode)
    INTO
      l_kocode
    FROM
      business_objects
    WHERE
        TYPE = p_doctype
      AND
        today_state = p_state
      AND
        name = p_sign;

    -- то объект не создается
    IF l_kocode IS NOT NULL THEN
      p_code := l_kocode;
      RETURN;

    END IF;

    -- иначе, определить номер ревизии
    SELECT
      Max(revision)
    INTO
      l_revision
    FROM
      konstrobj
    WHERE
        itemtype = l_kotype
      AND
        Sign = p_sign;

    -- если есть хотя бы одна ревизия
    IF l_revision IS NOT NULL THEN
      -- то выбрать сквозной код объекта
      SELECT
        prodcode,
        revsign
      INTO
        l_bpcode,
        l_revsign
      FROM
        business_objects
      WHERE
          TYPE = p_doctype
        AND
          name = p_sign
        AND
          revision = l_revision;

      l_newobj := FALSE;

    ELSE
      -- иначе создать новый
      l_bpcode := sq_production.NEXTVAL;

      INSERT INTO bo_production (
        code, Sign, TYPE
      )
      VALUES (
        l_bpcode, p_sign, p_doctype
      );

      l_newobj := TRUE;
      l_bocode := sq_business_objects_code.NEXTVAL;

      INSERT INTO omp_objects (
        code, objtype, scheme, num
      )
      VALUES (
        l_bocode, 1000090, NULL, so.getnextsonum()
      );

      INSERT INTO obj_attr_values_1000090 (
        socode
      )
      VALUES (
        l_bocode
      );

      INSERT INTO okp_boproduction_params (
        prodcode, socode
      )
      VALUES (
        l_bpcode, l_bocode
      );

    END IF;

    -- номер ревизии
    l_revision := Nvl(l_revision, -1) + 1;

    -- обозначение ревизии
    -- если у старой ревизии оно заполнено, то увеличивается на 1
    -- иначе приравнивается к номеру ревизии
    IF l_revsign IS NOT NULL THEN
      increvsign(l_revsign);

    ELSE
      l_revsign := To_Char(l_revision);

    END IF;

    -- ФИО пользователя
    SELECT
      fullname
    INTO
      l_username
    FROM
      user_list
    WHERE
        code = p_user;

    -- единицы измерения "ШТ."
    SELECT
      code
    INTO
      l_meascode
    FROM
      measures
    WHERE
        name = 'Штука';

    -- вид документа
    SELECT
      code
    INTO
      l_kind
    FROM
      ko_documents_kinds
    WHERE
        botype  = p_doctype;

    -- создание бизнес-объекта
    l_bocode := sq_business_objects_code.NEXTVAL;

    INSERT INTO omp_objects (
      code, objtype, scheme, num
    )
    VALUES (
      l_bocode, p_doctype, NULL, so.getnextsonum()
    );

    pkg_sepo_attr_operations.init(p_doctype);
    pkg_sepo_attr_operations.geninsertsql();
    pkg_sepo_attr_operations.executecommand(l_bocode);

    l_kocode := sq_unvcode.NEXTVAL;

    INSERT INTO business_objects (
      code, TYPE, doccode, owner, checkout, name, revision, revsign,
      prodcode, access_level, today_state, today_statedate, today_stateuser,
      create_date, create_user
    )
    VALUES (
      l_bocode, p_doctype, l_kocode, p_owner, NULL, p_sign, l_revision, l_revsign,
      l_bpcode, NULL, p_state, l_date, p_user,
      l_date, p_user
    );

    IF l_newobj THEN
      l_bphistcode := sq_bo_prod_history.NEXTVAL;

      INSERT INTO bo_production_history (
        code, prodcode, revision, bocode, insertdate, deletedate, action,
        usercode, promcode
      )
      VALUES (
        l_bphistcode, l_bpcode, l_revision, l_bocode, l_date, NULL, 0,
        p_user, NULL
      );

    END IF;

    -- применение alt кодов
    l_name := p_name;
    altapply(l_name);

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, l_kotype, l_bocode, 0, p_sign, l_name, NULL, l_koattr,
      l_kind, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    l_promcode := sq_businessobj_promotion_code.NEXTVAL;

    INSERT INTO businessobj_promotion (
      code, businessobj, operation, usercode, lastname, donedate, rdate,
      prev_state, current_state, note, statedate, todate, action,
      revision, iicode, mainpromcode
    )
    VALUES (
      l_promcode, l_bocode, NULL, p_user, l_username, l_date, l_date,
      NULL, p_state, NULL, l_date, l_date, 0, 0, NULL, l_promcode
    );

    set_approval_scheme(p_doctype, p_state, p_owner, l_bocode);

    p_code := l_kocode;

  END;

END;
/

GRANT EXECUTE ON pkg_sepo_tflex_synch_omp TO tflex_user;
