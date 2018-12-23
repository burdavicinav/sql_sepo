-- ������������ ������ � ��������
-- ������ ������� ������ ���������
-- ���� ���-�� ����������, ���� �������� ��������� ���������
SELECT
  p.code,
  p.Sign,
  p.TYPE,
  b.code,
  b.doccode,
  b.name,
  b.create_date
FROM
  bo_production p,
  business_objects b
WHERE
    b.prodcode = p.code
  AND
    b.TYPE = 256
  AND
    p.Sign != b.name;

-- ������������ ����������
SELECT
  name,
  Count(DISTINCT code)
FROM
  maretial_gosts
GROUP BY
  name
HAVING
  Count(DISTINCT code) > 1;