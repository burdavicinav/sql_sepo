SELECT
  dbf.MAT,
  dbf.NAIM,
  dbf.MARK,
  dbf.GRU,
  dbf.OBOZNGR
FROM
  sepo_maters dbf
WHERE
    dbf.MAT = dbf.GRU
  AND
    dbf.OBOZNGR IS NOT NULL
  AND
    EXISTS
    (
      SELECT 1 FROM sepo_maters s_
      WHERE
          s_.GRU = dbf.GRU
        AND
          s_.OBOZNGR IS NULL
    )
ORDER BY
  dbf.MAT;

SELECT
  dbf.MAT,
  dbf.NAIM,
  dbf.MARK,
  dbf.GRU,
  dbf.OBOZNGR
FROM
  sepo_maters dbf
WHERE
    dbf.MAT != dbf.GRU
  AND
    dbf.OBOZNGR IS NULL
  AND
    EXISTS
    (
      SELECT 1 FROM sepo_maters s_
      WHERE
          s_.MAT = s_.GRU
        AND
          s_.GRU = dbf.GRU
        AND
          s_.OBOZNGR IS NOT NULL
    )
ORDER BY
  dbf.MAT;