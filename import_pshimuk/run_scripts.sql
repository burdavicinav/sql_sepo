set serveroutput on;
set timing on;

DECLARE
  j NUMBER;
  l_div_999 NUMBER;
BEGIN
  DELETE FROM sepo_import_pshimuk_log;
  COMMIT;

  SELECT code INTO l_div_999 FROM divisionobj
  WHERE
      wsCode = '999';

  pkg_sepo_import_pshimuk.Init(
    p_userName => 'OMP_ADM',
    p_ownerName => 'ОАСУП',
    p_normStatus => pkg_sepo_import_pshimuk.NORM_STATE_CONFIRMED,
    p_notice => NULL --'Загружено автоматически'
  );

  j := 0;

  FOR i IN (
    SELECT
      Max(id),
      Max(shi),
      Max(shd),
      Max(prd),
      shm,
      coalesce(Max(prm), 0),
      Max(pri),
      coalesce(div.code, l_div_999) AS cex,
      ed,
      nr / 1000,
      CASE
        WHEN coalesce(chv, 0) = 0 THEN 999
        ELSE chv / 1000
      END,
      dce,
      tabn,
      datavk,
      dceSoCode,
      dceCode,
      dceType,
      matSoCode,
      matCode
--      div.Sign
    FROM
      view_sepo_pshimuk data,
      divisionobj div
    WHERE
        To_Char(data.cex) = div.wsCode(+)
--      AND
--        div.code IS NULL
--    WHERE
--        dce IS NOT NULL
--      AND
--        dce = '100000076703'
--      AND
--        id = 236052
--      AND
--        dceCode = 402440
    GROUP BY
      shm,
      cex,
      ed,
      nr,
      chv,
      dce,
      tabn,
      datavk,
      dceSoCode,
      dceCode,
      dceType,
      matSoCode,
      matCode,
      div.code
    ORDER BY
      dce,
      coalesce(Max(prm), 0),
      shm

  ) LOOP
    j := j + 1;

--    IF j > 20000 THEN EXIT; END IF;

    pkg_sepo_import_pshimuk.pkg_importRowData := i;

    pkg_sepo_import_pshimuk.CheckData();
    pkg_sepo_import_pshimuk.AddMaterial();
    pkg_sepo_import_pshimuk.CreateMainNorm();

  END LOOP;

  pkg_sepo_import_pshimuk.Clear();

END;
/

set timing off