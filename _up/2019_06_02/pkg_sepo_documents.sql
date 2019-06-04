CREATE OR REPLACE PACKAGE pkg_sepo_documents
AS
  PROCEDURE create_document(p_docname VARCHAR2, p_hash VARCHAR2, p_data BLOB, p_doccode OUT NUMBER);

  PROCEDURE attach_document(p_bocode NUMBER, p_doccode NUMBER, p_filegroup NUMBER);
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_documents
AS
  PROCEDURE create_document(p_docname VARCHAR2, p_hash VARCHAR2, p_data BLOB, p_doccode OUT NUMBER)
  IS
    l_date DATE := SYSDATE;
    l_user NUMBER;
  BEGIN
    SELECT
      code
    INTO
      l_user
    FROM
      user_list
    WHERE
        loginname = USER();

    SELECT
      Max(code)
    INTO
      p_doccode
    FROM
      documents_params
    WHERE
        Lower(name) = Lower(p_docname)
      AND
        Lower(HASH) = Lower(p_hash);

    IF p_doccode IS NULL THEN
      p_doccode := sq_documents_code.NEXTVAL;

      INSERT INTO documents (code) VALUES (p_doccode);

      INSERT INTO documents_parts (
        code, num, data
      )
      VALUES (
        p_doccode, 1, p_data
      );

      INSERT INTO documents_params (
        code, name, filename, moddate, rdate, f_credate, f_moddate,
        HASH, hash_alg, verdate, usercode
      )
      VALUES (
        p_doccode, p_docname, p_docname, l_date, l_date, l_date, l_date,
        p_hash, 1, l_date, l_user);

    END IF;

  END;

  PROCEDURE attach_document(p_bocode NUMBER, p_doccode NUMBER, p_filegroup NUMBER)
  IS
  BEGIN
    INSERT INTO attachments (
      code, businessobj, document, groupcode, hint
    )
    VALUES (
      sq_attachments_code.NEXTVAL, p_bocode, p_doccode, p_filegroup, 0
    );

  END;

END;
/