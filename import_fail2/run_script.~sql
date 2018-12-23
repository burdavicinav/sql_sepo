-- удаление данных
--DECLARE

--BEGIN
--  pkg_sepo_import_fail2.DeleteAllRoutes();
--  pkg_sepo_import_fail2.DeleteFromFileData();
--END;
--/

DECLARE
  begin_ TIMESTAMP;
BEGIN
  DELETE FROM sepo_import_fail2_log;
  COMMIT;

--  pkg_sepo_import_fail2.LoadRouteFromFile();
--  pkg_sepo_import_fail2.CexFileToDistricts();

  pkg_sepo_import_fail2.Init(
    p_userName => 'OMP_ADM',
    p_ownerName => 'ОАСУП',
    p_routeStatus => pkg_sepo_import_fail2.CONST_ROUTE_STATE_CONFIRMED,
    p_notice => NULL --'Загружено автоматически'
  );

  FOR i IN (
    SELECT
      id,
      fileName,
      dce,
      prizm,
      ocex,
      datv,
      datd,
      ppp,
      soCode,
      docCode,
      docType,
      spcCode,
      cntNum,
      cntDenom
    FROM
      view_sepo_fail2_import
--    WHERE
--        id = 201331
--      id = 225847
  ) LOOP
--    Dbms_Output.put_line(i.id);
--    SELECT systimestamp INTO begin_ FROM dual;

    pkg_sepo_import_fail2.pkg_importRow := i;
    pkg_sepo_import_fail2.CreateRoute();

--    p_sepo_log( To_Char(systimestamp - begin_) );


  END LOOP;


END;
/