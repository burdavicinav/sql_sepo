/* заполнение пунктов маршрутов */
INSERT INTO sepo_fail2_routes
SELECT
  NULL,
  id,
  To_Number(
      Substr(cexNumber, 4, Length(cexNumber) - 3)
      ) AS cexNumber,
    cexCode
  FROM
    sepo_fail2 data
  unpivot include nulls
  (cexCode FOR cexNumber IN (
    CEX1, CEX2, CEX3, CEX4,
    CEX5, CEX6, CEX7, CEX8,
    CEX9, CEX10, CEX11, CEX12,
    CEX13, CEX14, CEX15, CEX16,
    CEX17, CEX18, CEX19, CEX20,
    CEX21, CEX22, CEX23, CEX24)
    )
WHERE
    coalesce(cexCode,0) > 0;

/* связь цехов из файла импорта с пунктам маршрута */
INSERT INTO sepo_cex_to_district
SELECT
  fail2.cex AS cexCode,
--  d.shortName,
  coalesce(d.code,
    (SELECT Max(code) FROM districts WHERE shortName = '999')
    ) AS districtCode
FROM
  ( SELECT DISTINCT cex FROM sepo_fail2_routes ) fail2,
  districts d
WHERE
    To_Char(fail2.cex) = d.shortName(+);
--  AND
--    d.code IS NULL;

SELECT * FROM sepo_cex_to_district
WHERE
    districtCode IS NULL;