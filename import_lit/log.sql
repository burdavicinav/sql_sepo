SET heading OFF;
SET termout OFF;
SET feedback OFF;
--SET linesize 1500;
SET pagesize 0;
SET colsep |;

spool import_log.csv;

SELECT
  '��� �����;��� �������� �����;�����;' ||
  'OMP ��� �����;������������ �����;' ||
  'OMP ��� �������� �����;������������ �������� �����;' ||
  '������� ������������ ������� �����;' ||
  '�������� ������'
FROM
  dual;

SELECT
  sl.shm || ';' ||
  sl.shk || ';' ||
  CASE
    WHEN coalesce(sl.nr, 0 ) = 0 THEN prc / 100
    ELSE sl.nr / ssl.snr
  END || ';' ||
  mix.code || ';' ||
  mix.name || ';' ||
  elem.code || ';' ||
  elem.name || ';' ||
  ssl.isFullMix || ';' ||
  CASE
    WHEN mix.code IS NULL THEN '�� ������� �����!'
    WHEN ssl.isFullMix = 0 THEN '�������� ������ �����!'
    ELSE '�������������� ������!'
  END
FROM
  sepo_lit sl,
  materials mix,
  materials elem,
  (
  SELECT
    sl.shm,
    Sum(coalesce(sl.nr, 0)) AS snr,
    Min(
      CASE
        WHEN elem.code IS NOT NULL THEN 1
        ELSE 0
      END) AS isFullMix
  FROM
    sepo_lit sl,
    materials elem
  WHERE
      sl.shk = elem.plCode(+)
  GROUP BY
    sl.shm
  ) ssl
WHERE
    sl.shm = ssl.shm
  AND
    sl.shm = mix.plCode(+)
  AND
    sl.shk = elem.plCode(+)
  AND
    -- �� ������� ���� �����, ���� ���� �� ���� ������� �� �� �������
    ( mix.code IS NULL OR ssl.isFullMix = 0 )
ORDER BY
  sl.shm,
  sl.shk;

spool off;