SELECT * FROM measures WHERE shortname LIKE 'ив%';
SELECT * FROM owner_name;
SELECT * FROM businessobj_states WHERE botype = 31;

DECLARE
  l_type NUMBER;
  l_sign VARCHAR2(1000);
  l_name VARCHAR2(1000);
  l_meascode NUMBER;
  l_owner NUMBER;
  l_state NUMBER;
  l_file BLOB;
  l_code NUMBER;

BEGIN
  l_type := 2;
  l_sign := 'test_flex_det';
  l_name := 'test_flex_det_name';
  l_meascode := 106;
  l_owner := 0;
  l_state := 5164;
  l_file := NULL;

  p_sepo_fix_tflex_to_omp(
    l_type,
    l_sign,
    l_name,
    l_meascode,
    l_owner,
    l_state,
    l_file,
    l_code
    );

  Dbms_Output.put_line(l_code);

END;
/

DECLARE
  l_type NUMBER;
  l_sign VARCHAR2(1000);
  l_name VARCHAR2(1000);
  l_meascode NUMBER;
  l_owner NUMBER;
  l_state NUMBER;
  l_file BLOB;
  l_code NUMBER;

BEGIN
  l_type := 31;
  l_sign := 'test_flex_fix';
  l_name := 'test_flex_fix_name';
  l_meascode := 106;
  l_owner := 0;
  l_state := 110;
  l_file := NULL;

  p_sepo_fix_tflex_to_omp(
    l_type,
    l_sign,
    l_name,
    l_meascode,
    l_owner,
    l_state,
    l_file,
    l_code
    );

  Dbms_Output.put_line(l_code);

END;
/