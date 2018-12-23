-- ����������� ��������
-- ����������� ���, ��� ���� � �����
-- � �������� ����������� - ������������������, ������� � 8000000

-- ���������� �� ����� �� records
SELECT
  *
FROM
  v_sepo_std_import
WHERE
    lvl_classify IN (3726, 4208)
ORDER BY
  reckey,
  tblkey;

-- ������������
-- � �������� ����������� - "����������� ��� ��"
-- ������ ����������� �� �����������, ��� ��� ��������� ������
SELECT
  *
FROM
  v_sepo_std_import
WHERE
    lvl_classify = 3709
  AND
    sign_vo IS NULL
ORDER BY
  f_table,
  tblkey;

-- ����� ����, ������ ����� "��������.xml" ���� ������ �� ����������� ��� ��
-- ��� ����� �� ���������
-- ��������� ���� � ����� ������ ����
BEGIN
  DELETE FROM sepo_std_import_temp;

  INSERT INTO sepo_std_import_temp (
    id_record, id_parent_record, lvl_classify, lvl_type,
    f_level, reckey, tblkey, f_table, name, sign_vo, scheme_name, gost
  )
  SELECT
    *
  FROM
    v_sepo_std_import
  WHERE
      lvl_classify = 3709;

END;

SELECT
  reckey,
  tblkey,
  f_table,
  name,
  sign_vo AS designation
FROM
  sepo_std_import_temp i
WHERE
    sign_vo IN
    (
      SELECT
        i_.sign_vo
      FROM
        sepo_std_import_temp i_
      WHERE
          i_.sign_vo = i.sign_vo
      GROUP BY
        i_.sign_vo
      HAVING
        Count(DISTINCT i_.id_record) > 1
    )
ORDER BY
  sign_vo,
  f_table,
  tblkey;

-- ���� ��������� ��� �����������. ����� 3709 � ������� �������������
-- �� ����������� � �������
SELECT
  f.id,
  f.id_record,
  f.id_field,
  f.id_tool,
  f.field_value,
  t.f_table,
  t.f_descr,
  r.f_key,
  fl.f_data,
  fl.f_longname
FROM
  sepo_std_formulas f,
  sepo_std_table_records r,
  sepo_std_tables t,
  sepo_std_table_fields fl
WHERE
    r.id = f.id_record
  AND
    t.id = r.id_table
  AND
    f.id_field = fl.id
  AND
    fl.f_longname = '����������� ��� ��'
  AND
    t.f_table = 'TBL011308'
  AND
    r.f_key = 91;