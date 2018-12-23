SET heading OFF;
SET termout OFF;
SET feedback OFF;
SET linesize 1100;
SET pagesize 0;
SET colsep |;

spool import_log.txt;

SELECT
  maters.id,
  maters.MAT,
  log_.message
FROM
  sepo_maters maters,
  sepo_import_maters_log log_
WHERE
    maters.id = log_.id
ORDER BY
  maters.id;

spool off;
