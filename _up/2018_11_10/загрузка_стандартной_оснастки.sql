BEGIN
  FOR i IN (
    SELECT
      trigger_name
    FROM
      sepo_import_triggers_disable

  ) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_name || ' disable';

  END LOOP;

END;
/

EXEC pkg_sepo_import_global.loadstdfixture(218, 93, 106, 120);

EXEC pkg_sepo_import_global.loadoldfixture(218, 93, 106, 115);