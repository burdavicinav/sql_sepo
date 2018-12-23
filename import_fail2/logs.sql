/* logs */

/* более одного маршрута на ДСЕ */
SELECT
  dce,
  coalesce(prizm,0) AS prizm
FROM
  sepo_fail2
WHERE
    fileName = 'fail2.dbf'
GROUP BY
  dce,
  coalesce(prizm,0)
HAVING
  Count(*) > 1
ORDER BY
  dce;

/* пустые маршруты */
SELECT
  *
FROM
  sepo_fail2 data
WHERE
    data.fileName = 'fail2.dbf'
  AND
    NOT EXISTS
    (
      SELECT 1 FROM sepo_fail2_routes items
      WHERE
          items.id_fail2 = data.id
    )
ORDER BY
  dce;

/* не задан основной цех */
SELECT
  *
FROM
  sepo_fail2 data
WHERE
    data.fileName = 'fail2.dbf'
  AND
    coalesce(data.ocex,0) = 0
ORDER BY
  dce;

/* задан только первый цех */
SELECT
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  data.cex1,
  data.cex2
FROM
  sepo_fail2 data,
  sepo_fail2_routes items
WHERE
    data.fileName = 'fail2.dbf'
  AND
    items.id_fail2 = data.id
GROUP BY
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  data.cex1,
  data.cex2
HAVING
  Count(*) = 1;

/* данные по маршруту */
SELECT
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  listagg(items.cex,';') within GROUP( ORDER BY items.number_)
FROM
  sepo_fail2 data,
  sepo_fail2_routes items
WHERE
    data.fileName = 'fail2.dbf'
  AND
    items.id_fail2 (+)= data.id
GROUP BY
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex;

SELECT
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  data.cex1,
--  items.number_,
  items.cex
FROM
  sepo_fail2 data,
  sepo_fail2_routes items
WHERE
    data.fileName = 'fail2.dbf'
  AND
    data.id = items.id_fail2
  AND
    items.number_ = (
      SELECT Max(items_.number_) FROM sepo_fail2_routes items_
      WHERE
        items_.id_fail2 = items.id_fail2
    );

/* последний пункт маршрута ДСЕ не равен первому пункту у входимости */
SELECT
  data.dce,
  data.docCode,
  data.routeString,
  data.firstDistrict,
  data.endDistrict,
  spcData.dce,
  spcData.docCode,
  spcData.routeString,
  spcData.firstDistrict,
  spcData.endDistrict
FROM
  view_sepo_fail2_data data,
  specifications spec,
  view_sepo_fail2_data spcData
WHERE
    data.fileName = 'fail2.xls'
  AND
    spcData.fileName = 'fail2.xls'
  AND
    data.docCode = spec.code
  AND
    spec.spcCode = spcData.docCode
  AND
    data.endDistrict != spcData.firstDistrict;

/* автозаполнение пунктов маршрута цехами из файла */
DECLARE

BEGIN
  FOR i IN (
    SELECT DISTINCT cex FROM sepo_fail2_routes

  ) LOOP
    INSERT INTO districts
    VALUES
    ('test_' || i.cex,
      districts_code.NEXTVAL,
        i.cex,
        1062,
          0,
            0,
              0,
                560,
                  0,
                    NULL,
                      NULL,
                        NULL,
                        0,
                          NULL,
                            NULL,
                              NULL,
                                0);

  END LOOP;

END;
/