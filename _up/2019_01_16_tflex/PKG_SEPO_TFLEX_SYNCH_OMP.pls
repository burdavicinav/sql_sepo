PROMPT CREATE OR REPLACE PACKAGE pkg_sepo_tflex_synch_omp
CREATE OR REPLACE PACKAGE pkg_sepo_tflex_synch_omp
AS
  PROCEDURE create_spec_fix (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
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
  PROCEDURE create_spec_fix (
    p_sign VARCHAR2,
    p_name VARCHAR2,
    p_owner NUMBER,
    p_state NUMBER,
    p_user NUMBER,
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
        code
      INTO
        l_bpcode
      FROM
        bo_production
      WHERE
          TYPE = 31
        AND
          Sign = l_bosign;

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
      l_bocode, 31, l_kocode, p_owner, NULL, l_bosign, l_revision, NULL,
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

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 31, l_bocode, 0, l_bosign, p_name, NULL, 1,
      NULL, 0, p_owner, 0, l_date, l_meascode, l_revision,
      l_bpcode, NULL, NULL
    );

    INSERT INTO fixture_base (
      code, kotype, fixture_types_code, originalname
      )
    VALUES (
      l_kocode, 31, NULL, p_sign
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
        code
      INTO
        l_bpcode
      FROM
        bo_production
      WHERE
          TYPE = 2
        AND
          Sign = p_sign;

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
      l_bocode, 2, l_kocode, p_owner, NULL, p_sign, l_revision, NULL,
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

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 2, l_bocode, 0, p_sign, p_name, NULL, -1,
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
    l_date := SYSDATE;

    SELECT
      bocode
    INTO
      l_bocode
    FROM
      konstrobj
    WHERE
        unvcode = p_code;

    SELECT
      Max(code)
    INTO
      l_doc
    FROM
      documents_params
    WHERE
        Lower(name) = Lower(p_fname)
      AND
        Lower(HASH) = Lower(p_fhash);

    IF l_doc IS NULL THEN
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

    END IF;

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

--    SELECT
--      Count(1)
--    INTO
--      l_cnt
--    FROM
--      attachments a
--    WHERE
--        a.businessobj = l_bocode
--      AND
--        a.document = l_doc;

--    IF l_cnt = 0 THEN
      INSERT INTO attachments (
        code, businessobj, document, groupcode, hint,
        additional_to
      )
      VALUES (
        sq_attachments_code.NEXTVAL, l_bocode, l_doc, p_groupcode, 0,
        p_linkdoccode
      );

--    END IF;

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
        code
      INTO
        l_bpcode
      FROM
        bo_production
      WHERE
          TYPE = 6
        AND
          Sign = p_sign;

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
      l_bocode, 6, l_kocode, p_owner, NULL, p_sign, l_revision, NULL,
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

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, 6, l_bocode, 0, p_sign, p_name, NULL, -1,
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
        code
      INTO
        l_bpcode
      FROM
        bo_production
      WHERE
          TYPE = p_doctype
        AND
          Sign = p_sign;

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
      l_bocode, p_doctype, l_kocode, p_owner, NULL, p_sign, l_revision, NULL,
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

    INSERT INTO konstrobj (
      unvcode, itemcode, itemtype, bocode, docletter, Sign, name, notice, attr,
      kind, supplytype, owner, protection, recdate, meascode, revision,
      prodcode, formedfrom, formedtype
    )
    VALUES (
      l_kocode, l_kocode, l_kotype, l_bocode, 0, p_sign, p_name, NULL, l_koattr,
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

    p_code := l_kocode;

  END;

END;
/

GRANT EXECUTE ON pkg_sepo_tflex_synch_omp TO tflex_user;
