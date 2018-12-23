CREATE OR REPLACE VIEW view_sepo_pshimuk
AS
SELECT
  data.*,
  bo.code AS dceSoCode,
  ko.unvCode AS dceCode,
  ko.itemType AS dceType,
  mats.soCode AS matSoCode,
  mats.code AS matCode
FROM
  sepo_pshimuk data,
  view_sepo_union_attrs_dce dce,
  business_objects bo,
  konstrobj ko,
  materials mats
WHERE
    data.dce = dce.value_(+)
  AND
    dce.soCode = bo.code(+)
  AND
    bo.docCode = ko.unvCode(+)
  AND
    data.shm = mats.plCode(+);