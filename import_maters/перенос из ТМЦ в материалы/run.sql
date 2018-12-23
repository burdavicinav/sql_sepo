DECLARE
  l_stock_other NUMBER;
  l_div_999 NUMBER;
BEGIN
  -- очищение логов
  DELETE FROM sepo_import_maters_log;
  DELETE FROM sepo_import_pshimuk_log;
  COMMIT;

  -- настройка загрузки материалов
  pkg_sepo_import_maters.Init(
    p_userName => 'OMP_ADM',
    p_ownerName => 'ОАСУП',
    p_matState => pkg_sepo_import_maters.MAT_STATE_CONFIRMED,
    p_notice => NULL, --'Загружено автоматически'
    p_classifyname => 'FoxPro'
  );

  -- запрос на удаление ТМЦ / загрузку материалов
  FOR i IN (
    SELECT
      maters.*
    FROM
      stock_other so_,
      sepo_maters maters
    WHERE
        maters.id_load = 4
      AND
        so_.Sign = maters.mat
  ) LOOP
    -- получение кода ТМЦ по обозначению
    SELECT
      code
    INTO
      l_stock_other
    FROM
      stock_other
    WHERE
        Sign = i.MAT;

    -- удаление ТМЦ
    pkg_sepo_materials.DeleteStockItem(l_stock_other);

    pkg_sepo_import_maters.pkg_importRowMaterialData := i;
    -- создание материала
    pkg_sepo_import_maters.CreateMaterial();

  END LOOP;

  -- очищение настроек
  pkg_sepo_import_maters.Clear();

  SELECT code INTO l_div_999 FROM divisionobj
  WHERE
      wsCode = '999';

  -- настройка загрузки норм
  pkg_sepo_import_pshimuk.Init(
    p_userName => 'OMP_ADM',
    p_ownerName => 'ОАСУП',
    p_normStatus => pkg_sepo_import_pshimuk.NORM_STATE_CONFIRMED,
    p_notice => NULL --'Загружено автоматически'
  );

  -- нормы расхода на созданный материал
  FOR j IN (
    SELECT
      Max(id),
      Max(shi),
      Max(shd),
      Max(prd),
      shm,
      coalesce(Max(prm), 0),
      Max(pri),
      coalesce(div.code, 111) AS cex,
      ed,
      nr / 1000,
      CASE
        WHEN coalesce(chv, 0) = 0 THEN 999
        ELSE chv / 1000
      END,
      dce,
      tabn,
      datavk,
      id_load,
      dceSoCode,
      dceCode,
      dceType,
      matSoCode,
      matCode
    FROM
      view_sepo_pshimuk data,
      divisionobj div
    WHERE
        data.id_load = 5
      AND
        EXISTS
        (
            SELECT 1 FROM sepo_maters maters
            WHERE
                maters.id_load = 4
              AND
                maters.mat = data.shm
        )
      AND
        To_Char(data.cex) = div.wsCode(+)
      AND
        dce IS NOT NULL
    GROUP BY
      shm,
      cex,
      ed,
      nr,
      chv,
      dce,
      tabn,
      datavk,
      id_load,
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
    pkg_sepo_import_pshimuk.pkg_importRowData := j;

    pkg_sepo_import_pshimuk.CheckData();
    pkg_sepo_import_pshimuk.AddMaterial();
    pkg_sepo_import_pshimuk.CreateMainNorm();

  END LOOP;

  pkg_sepo_import_pshimuk.Clear();

END;
/