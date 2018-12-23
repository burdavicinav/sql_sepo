-- ����� ��������� ���������� � ��
SELECT Count(*) FROM konstrobj
WHERE
    itemType = 5;

-- ������ ��������� ����������, �������� � ��� � ����� ������������
SELECT
  ko.prodCode,
  ko.Sign,
  Count(DISTINCT spc.prodCode)
FROM
  konstrobj ko,
  specifications sp,
  konstrobj spc
WHERE
    ko.itemType = 5
  AND
    sp.code = ko.unvCode
  AND
    spc.unvCode = sp.spcCode
GROUP BY
  ko.prodCode,
  ko.Sign
HAVING
  Count(DISTINCT spc.prodCode) > 1
ORDER BY
  ko.Sign;

-- ��������
-- �������� ���������, �������� ������ � ���� ������������ (��� ����� �������)
-- ����� ����������� ��������� ����������� ���:
-- ����������� ����� ������ + "-" + ����� ������� (���, ��� ����� �����
-- '-' � '�'(��� �������) � ������� ����������� ���������) + "�"
CREATE OR REPLACE VIEW view_sepo_spc_materials_update
AS
SELECT
  ko.unvCode AS mat_code,
  ko.prodCode AS mat_prodcode,
  ko.Sign AS mat_sign,
  ko.revision AS mat_revision,
  spc.unvCode AS spec_code,
  spc.prodCode AS spec_prodcode,
  spc.Sign AS spec_sign,
  spc.revision AS spec_revision,
  sp.position AS position_spec,
  regexp_replace(ko.Sign, '-\w{1,}�?$', '') AS spec_section,
  regexp_substr(ko.Sign, '-\w{1,}�?$') AS position_section,
  spc.Sign ||
  '-' ||
  regexp_replace(regexp_substr(ko.Sign, '-\w{1,}�?$'), '-|�', '') ||
  --regexp_replace(regexp_substr(ko.Sign, '-\d{1,}�?$'), '\D', '') ||
  '�'
    AS new_mat_sign
FROM
  (
  SELECT
    ko.prodCode,
    Count(DISTINCT spc.prodCode)
  FROM
    konstrobj ko,
    specifications sp,
    konstrobj spc
  WHERE
      ko.itemType = 5
    AND
      sp.code = ko.unvCode
    AND
      spc.unvCode = sp.spcCode
  GROUP BY
    ko.prodCode
  HAVING
    Count(DISTINCT spc.prodCode) = 1
  ) alg,
  konstrobj ko,
  specifications sp,
  konstrobj spc
WHERE
    ko.prodCode = alg.prodCode
  AND
    sp.code = ko.unvCode
  AND
    spc.unvCode = sp.spcCode
ORDER BY
  ko.Sign,
  spc.Sign;

-- ���������, ������������ ����������
SELECT * FROM view_sepo_spc_materials_update up;

-- ������ ����������, ������� ����������� ������ �������
-- ��������� � ����������� ������� ������
SELECT
  up.*,
  regexp_replace(up.spec_sign, '\W', ''),
  regexp_replace(up.spec_section, '\W', '')
FROM
  view_sepo_spc_materials_update up
WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '');

-- ������ ����������, ������� ����������� ������ �������
-- �� ��������� � ����������� ������� ������
SELECT
  up.*,
  regexp_replace(up.spec_sign, '\W', ''),
  regexp_replace(up.spec_section, '\W', '')
FROM
  view_sepo_spc_materials_update up
WHERE
    regexp_replace(up.spec_sign, '\W', '') !=
      regexp_replace(up.spec_section, '\W', '');

-- ����� ����������� ������ ���������� ���������
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    new_mat_sign
  FROM
    view_sepo_spc_materials_update
  GROUP BY
    new_mat_sign
  HAVING
    Count(DISTINCT mat_prodcode) > 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- ����, ��� � ���������� ������, ������ ����� �������������� �����
-- ����������, ���������� ����������
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) > 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- � ����� ������ ���������� ��� ����������
SELECT
  a.*
FROM
  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) = 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
--  AND
--    a.mat_sign = a.new_mat_sign
  AND
    regexp_replace(a.spec_sign, '\W', '') =
      regexp_replace(a.spec_section, '\W', '')
ORDER BY
  a.new_mat_sign,
  a.mat_sign;

-- ����� �� �������� chndn
SELECT * FROM obj_attributes
WHERE
    objType = 5
  AND
    shortName = 'CHNDN';

-- 7458
SELECT
  ko.unvcode,
  ko.prodcode,
  ko.Sign,
  attr_5.A_7458 -- ��� �� ������� ����
FROM
  konstrobj ko,
  business_objects bo,
  obj_attr_values_5 attr_5
WHERE
    ko.itemType = 5
  AND
    ko.unvCode = bo.doccode
  AND
    ko.prodcode = bo.prodcode
  AND
    attr_5.socode = bo.code
  AND
    attr_5.A_7458 IS NULL;

-- ���� ������ ��������...


-- �������� ����� ���������� ������ � �������
-- �������� ������� ���� ������������� � 4 ����
CREATE TABLE sepo_spc_materials_update
AS
SELECT * FROM view_sepo_spc_materials_update;

-- �������� �� ������������� ����������, ����������� ������ �������
-- ��������� � ����� �������������� ����� ���������

-- ����������� ������ �� 0.5 �������
SELECT
  a.*
FROM
  sepo_spc_materials_update a,
--  view_sepo_spc_materials_update a,
  (
  SELECT
    up.new_mat_sign
  FROM
    sepo_spc_materials_update up
--    view_sepo_spc_materials_update up
  WHERE
    regexp_replace(up.spec_sign, '\W', '') =
      regexp_replace(up.spec_section, '\W', '')
  GROUP BY
    up.new_mat_sign
  HAVING
    Count(DISTINCT up.mat_prodcode) = 1
  ) b
WHERE
    a.new_mat_sign = b.new_mat_sign
--  AND
--    a.mat_sign = a.new_mat_sign
  AND
    regexp_replace(a.spec_sign, '\W', '') =
      regexp_replace(a.spec_section, '\W', '')
  AND
    EXISTS
    (
      SELECT 1 FROM bo_production bo
      WHERE
          bo.Sign = a.new_mat_sign
        AND
          bo.code != a.mat_prodcode
        AND
          bo.TYPE = 5
    )
ORDER BY
  a.new_mat_sign,
  a.mat_sign


-- ���� ��������� ������� ��������, �� �����.
-- ��� ���� �������� � ����� ������������ � ����
-- ��� �� � ��������� �������
SELECT * FROM bo_production
WHERE
    TYPE = 5
  AND
    Sign = <new_mat_sign �� ����������� �������>;