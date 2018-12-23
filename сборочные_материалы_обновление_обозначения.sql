-- обновление обозначени€ сборочных материалов
-- удал€ютс€ пробелы в начале обозначени€

-- отключение триггеров
ALTER TRIGGER taiud_konstrobj_sosign DISABLE;
ALTER TRIGGER taiur_konstrobj_sosign DISABLE;
ALTER TRIGGER taur_konstrobj_sosign DISABLE;
ALTER TRIGGER tbiu_konstrobj_sosign DISABLE;
ALTER TRIGGER tua_konstrobj DISABLE;
ALTER TRIGGER tub_stockobj DISABLE;
ALTER TRIGGER tbiu_stockobj DISABLE;
ALTER TRIGGER taiur_stockobj DISABLE;
ALTER TRIGGER taiud_stockobj DISABLE;

-- bo_production
UPDATE bo_production SET Sign = LTrim(sign)
WHERE
    code IN (
      SELECT ko.prodCode FROM konstrobj ko
      WHERE
          ko.itemType = 5
        AND
          regexp_like(ko.Sign, '^ +')
    );

-- business_objects
UPDATE business_objects SET name = LTrim(name)
WHERE
    prodCode IN (
      SELECT ko.prodCode FROM konstrobj ko
      WHERE
          ko.itemType = 5
        AND
          regexp_like(ko.Sign, '^ +')
    );

-- konstrobj
UPDATE konstrobj SET Sign = LTrim(sign)
WHERE
    prodCode IN (
      SELECT ko.prodCode FROM konstrobj ko
      WHERE
          ko.itemType = 5
        AND
          regexp_like(ko.Sign, '^ +')
    );

-- spcMaterials
UPDATE spcMaterials SET Sign = LTrim(sign)
WHERE
    code IN (
      SELECT code FROM spcMaterials
      WHERE
          regexp_like(Sign, '^ +')
    );

-- stockobj
UPDATE stockObj
SET
  desc_update_check = 1,
  description = LTrim(description),
  Sign = LTrim(sign)
WHERE
    code IN (
      SELECT code FROM stockObj
      WHERE
          baseType = 0
        AND
          SUBTYPE = 5
        AND
          regexp_like(Sign, '^ +')
    );

COMMIT;

-- включение триггеров
ALTER TRIGGER taiud_konstrobj_sosign ENABLE;
ALTER TRIGGER taiur_konstrobj_sosign ENABLE;
ALTER TRIGGER taur_konstrobj_sosign ENABLE;
ALTER TRIGGER tbiu_konstrobj_sosign ENABLE;
ALTER TRIGGER tua_konstrobj ENABLE;
ALTER TRIGGER tub_stockobj ENABLE;
ALTER TRIGGER tbiu_stockobj ENABLE;
ALTER TRIGGER taiur_stockobj ENABLE;
ALTER TRIGGER taiud_stockobj ENABLE;