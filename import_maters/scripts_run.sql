set serveroutput on;
set timing on;

DECLARE
  l_isMaterial NUMBER;

BEGIN
  DELETE FROM sepo_import_maters_log;
  COMMIT;

  pkg_sepo_import_maters.Init(
    p_userName => 'OMP_ADM',
    p_ownerName => 'ОАСУП',
    p_matState => pkg_sepo_import_maters.MAT_STATE_CONFIRMED,
    p_notice => NULL --'Загружено автоматически'

  );

  FOR i IN (
    SELECT
      imp.*
    FROM
      sepo_maters imp
    WHERE
      imp.OBOZNGR IS NULL
    AND
      imp.MAT != coalesce( imp.GRU, -1 )

  ) LOOP
    pkg_sepo_import_maters.pkg_importRowMaterialData := i;

    SELECT
      Count(*)
    INTO
      l_isMaterial
    FROM
      sepo_shm_list
    WHERE
        shm = i.mat;

    IF l_isMaterial > 0 THEN
      pkg_sepo_import_maters.CreateMaterial();
    ELSE
      pkg_sepo_import_maters.CreateOtherItem();

    END IF;


  END LOOP;


END;
/

set timing off;