-- ���� �� ��
SELECT DISTINCT
  f_value
FROM
  sepo_tp_fields
WHERE
    Lower(field_name) LIKE '%ceh%';

-- ������������� �����
-- tp_workshop - ���, ��������� � �����
-- subst_workshop - ���-����������
-- substr_section - �������-����������
SELECT
  *
FROM
  sepo_tp_workshops_subst;

-- ���� � ������ ������� ���� ����, ������� ��� � ������ �������,
-- �� �������� � ������, � ������� � �������