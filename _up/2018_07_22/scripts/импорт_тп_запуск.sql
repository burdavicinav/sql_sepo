--EXEC pkg_sepo_import_global.saveimporttpdata();

DECLARE
  l_groupcode NUMBER;
  l_letter NUMBER;
  l_state NUMBER;
  l_owner NUMBER;
BEGIN
  l_groupcode := 11;
  l_letter := 0;
  l_state := 100;
  l_owner := 93;

  pkg_sepo_import_global.importtp(
    l_groupcode,
    l_letter,
    l_state,
    l_owner
    );

END;
/