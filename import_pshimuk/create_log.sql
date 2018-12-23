SET heading OFF;
SET termout OFF;
SET feedback OFF;
SET linesize 1500;
SET pagesize 0;
SET colsep |;

spool import_log.txt;

SELECT
  data.id || ' ' ||
  data.shm || ' ' ||
  ko.Sign || ' ' ||
  log_.message
FROM
  view_sepo_pshimuk data,
  sepo_import_pshimuk_log log_,
  konstrobj ko
WHERE
    data.id = log_.id
  AND
    data.dceCode = ko.unvCode(+)
ORDER BY
  data.id;

spool off;
