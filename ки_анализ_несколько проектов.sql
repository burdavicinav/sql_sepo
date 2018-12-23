SELECT
  -- код строки ии
  alg.kiCode AS iiCode,
  -- наименование ии
  bo.name AS iiName,
  -- дата создания ии
  bo.create_date AS iiDate,
  -- наименование кэ
  ko.name AS koName,
  -- ревизия кэ
  ko.revision AS koRevision,
  -- строка ревизий на проекте
  listAgg(
    CASE
      WHEN cnt_rev > 1 THEN messagePart
      ELSE NULL
    END, '; '
    ) within GROUP (ORDER BY itemFlag) AS msg_warning
FROM
  (
  SELECT
    d.kiCode,
    d.itemFlag,
    d.itemSign,
    bo_rev.prodCode,
    d.itemSign || '{' ||
      listAgg(bo_rev.revision, ', ') within GROUP (ORDER BY bo_rev.revision)
        || '}' AS messagePart,
    Count(DISTINCT bo_rev.revision) AS cnt_rev
  FROM
    (
    SELECT
      ki.kiCode AS docCode,
      ki.code AS kiCode,
      ii.itemCode AS itemCode,
      0 AS itemFlag,
      CASE
        WHEN ki.docType IN (7, 23) THEN 'гр. '
        ELSE NULL
      END AS itemSign
    FROM
      ki_item ki,
      ii_items ii
    WHERE
        ii.code = ki.itemCode

    UNION ALL

    SELECT
      ki.kiCode AS docCode,
      ki.code,
      ko.boCode,
      1 AS itemFlag,
      coalesce(regexp_substr(ko.Sign, '-\d{2}$'), '-00') || ' ' AS itemSign
    FROM
      ki_item ki,
      ii_items ii,
      grspc_rel gr,
      konstrobj ko
    WHERE
        ii.code = ki.itemCode
      AND
        ki.docType IN (7,23)
      AND
        gr.grCode = ki.docCode
      AND
        ko.unvCode = gr.code
      AND
        gr.deleteDate IS NULL
    ) d,
    business_objects bo,
    business_objects bo_rev,
    businessobj_promotion bop,
    businessobj_states cs,
    businessobj_promotion_levels lvl
  WHERE
      bo.code = d.itemCode
    AND
      bo_rev.prodCode = bo.prodCode
    AND
      bop.businessObj = bo_rev.code
    AND
      bop.code = (
        SELECT
          Max(bop_.code)
        FROM
          businessobj_promotion bop_
        WHERE
            bop_.businessObj = bop.businessObj
      )
    AND
      cs.code = bop.current_state
    AND
      lvl.code = cs.promLevel
    AND
      lvl.name IN ('Проектирование', 'Подготовка производства')
  GROUP BY
    d.kiCode,
    d.itemFlag,
    d.itemSign,
    bo_rev.prodCode
  ) alg,
  ki_item ki,
  business_objects bo,
  ii_items ii,
  business_objects ko
WHERE
    alg.kiCode = ki.code
  AND
    bo.code = ki.kiCode
  AND
    ii.code = ki.itemCode
  AND
    ko.code = ii.itemCode
GROUP BY
  alg.kiCode,
  bo.name,
  bo.create_date,
  ko.name,
  ko.revision
ORDER BY
  bo.create_date,
  bo.name,
  ko.name,
  ko.revision;