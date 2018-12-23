DECLARE
  l_tpcode NUMBER;
  l_tptype NUMBER;
  l_sign techprocesses.Sign%TYPE;
  l_name techprocesses.name%TYPE;
  l_dobjcode NUMBER;
  l_groupcode NUMBER;
  l_letter NUMBER;
  l_state NUMBER;
  l_owner NUMBER;
  l_remark CLOB;

  l_kocode NUMBER;
  l_tporder NUMBER;
  l_tptoko NUMBER;

  l_operation NUMBER;
  l_opernum VARCHAR2(10);
  l_wscode NUMBER;
  l_opercode NUMBER;
  l_instruction NUMBER;

  l_stepcode NUMBER;
  l_stepnum NUMBER;
  l_tpstep NUMBER;
BEGIN
  l_tptype := 0;
  l_sign := 'test2';
  l_name := 'test22';
  l_dobjcode := NULL;
  l_groupcode := NULL;
  l_letter := 0;
  l_state := 100;
  l_owner := 93;
  l_remark := 'тест 123 sdfsd';

  l_tpcode := pkg_sepo_techprocesses.createobj(
    l_tptype,
    l_sign,
    l_name,
    l_dobjcode,
    l_groupcode,
    l_letter,
    l_state,
    l_owner,
    l_remark
  );

  l_kocode := 428301;
  l_tporder := 1;

  l_tptoko := pkg_sepo_techprocesses.addkonstrobj(
    l_tpcode,
    l_tptype,
    l_kocode,
    l_tporder
  );

  l_opernum := '005';
  l_wscode := 1186;
  l_opercode := 28255;

  l_operation := pkg_sepo_techprocesses.addoperation (
    l_tpcode,
    l_opernum,
    l_wscode,
    l_opercode,
    l_remark,
    NULL,
    NULL,
    NULL
  );

  l_instruction := 702;

  pkg_sepo_techprocesses.addinstruction (
    l_operation,
    l_instruction,
    0
  );

  l_stepcode := 97290;
  l_stepnum := 1;

  l_tpstep := pkg_sepo_techprocesses.addstep (
    l_operation,
    l_stepcode,
    l_stepnum,
    l_remark
  );

  pkg_sepo_techprocesses.addperformeronstep (
    l_tpstep,
    1,
    18092,
    2,
    0
  );

  pkg_sepo_techprocesses.addequipmentmodel (
    l_operation,
    25119,
    0
  );

  pkg_sepo_techprocesses.addequipmentmodel (
    l_operation,
    25120,
    1
  );

  pkg_sepo_techprocesses.addfixtureonstep (
    l_tpstep,
    612971,
    1,
    10,
    0
  );

  pkg_sepo_techprocesses.addfixtureonstep (
    l_tpstep,
    612972,
    1,
    10,
    1
  );

  pkg_sepo_techprocesses.addfixtureonstep (
    l_tpstep,
    612973,
    1,
    10,
    2
  );

  COMMIT;

END;
/