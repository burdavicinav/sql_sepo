-- список материалов для обновления
SELECT
  *
FROM
  bo_production
WHERE
    TYPE = 5
  AND
    Sign LIKE '%\%';

-- отключение триггеров

ALTER TRIGGER taiud_konstrobj_sosign DISABLE;
ALTER TRIGGER taiur_konstrobj_sosign DISABLE;
ALTER TRIGGER taur_konstrobj_sosign DISABLE;
ALTER TRIGGER tbiu_konstrobj_sosign DISABLE;
ALTER TRIGGER tua_konstrobj DISABLE;
ALTER TRIGGER tua_spcmaterials DISABLE;
ALTER TRIGGER tub_stockobj DISABLE;
ALTER TRIGGER tbiu_stockobj DISABLE;
ALTER TRIGGER taiur_stockobj DISABLE;
ALTER TRIGGER taiud_stockobj DISABLE;
ALTER TRIGGER tbu_sepo_konstrobj DISABLE;
ALTER TRIGGER tbu_sepo_business_objects DISABLE;

-- обновление таблиц

UPDATE bo_production SET Sign = REPLACE(Sign, '\', '')
WHERE
    type = 5
  AND
    Sign LIKE '%\%';

UPDATE business_objects SET name = REPLACE(name, '\', '')
WHERE
    type = 5
  AND
    name LIKE '%\%';

UPDATE konstrobj SET Sign = REPLACE(Sign, '\', '')
WHERE
    itemType = 5
  AND
    Sign LIKE '%\%';

UPDATE spcMaterials SET Sign = REPLACE(Sign, '\', '')
WHERE
    Sign LIKE '%\%';

UPDATE stockobj
SET
  Sign = REPLACE(Sign, '\', ''),
  description = REPLACE(description, '\', ''),
  desc_update_check = 1
WHERE
    baseType = 0
  AND
    SUBTYPE = 5
  AND
    Sign LIKE '%\%';

COMMIT;

-- включение триггеров

ALTER TRIGGER taiud_konstrobj_sosign ENABLE;
ALTER TRIGGER taiur_konstrobj_sosign ENABLE;
ALTER TRIGGER taur_konstrobj_sosign ENABLE;
ALTER TRIGGER tbiu_konstrobj_sosign ENABLE;
ALTER TRIGGER tua_konstrobj ENABLE;
ALTER TRIGGER tua_spcmaterials ENABLE;
ALTER TRIGGER tub_stockobj ENABLE;
ALTER TRIGGER tbiu_stockobj ENABLE;
ALTER TRIGGER taiur_stockobj ENABLE;
ALTER TRIGGER taiud_stockobj ENABLE;
ALTER TRIGGER tbu_sepo_konstrobj ENABLE;
ALTER TRIGGER tbu_sepo_business_objects ENABLE;