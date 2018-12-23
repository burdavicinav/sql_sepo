DECLARE
  l_old_cut NUMBER;
  l_new_cut NUMBER;
  l_query VARCHAR2(500);
  l_cut_uncorrect_value VARCHAR2(255);

  ATTR_NOT_EXISTS_EXCEPTION EXCEPTION;
  ATTR_NOT_CORRECT_VALUE_EXCEPTION EXCEPTION;
BEGIN
  -- ������ ��������� �������� �� ���������� �������� "�������"
  -- � ����� �������� ������� "�������_".
  -- ������������ �� ��������� RUSSIAN_RUSSIA.CL8MSWIN1251

  -- ��������� ����� ��������� "�������" � "�������_"
  SELECT
    Max(code)
  INTO
    l_old_cut
  FROM
    obj_attributes
  WHERE
      objType = 1000001
    AND
      shortName = '�������';

  SELECT
    Max(code)
  INTO
    l_new_cut
  FROM
    obj_attributes
  WHERE
      objType = 1000001
    AND
      shortName = '�������_';

  -- ���� ���� �� ������ �� ��� �� ����������, �� ������
  IF l_old_cut + l_new_cut IS NULL THEN
    RAISE ATTR_NOT_EXISTS_EXCEPTION;
  END IF;

  -- ����� �������� �� ������������ �������� �������� "�������"
  l_query :=
    'SELECT max(A_' || l_old_cut || ') FROM obj_attr_values_1000001 ' ||
    'WHERE NOT regexp_like(A_' || l_old_cut || ', ''^\d+([\.,]\d+)?$'')';

--  Dbms_Output.put_line(l_query);

  EXECUTE IMMEDIATE l_query INTO l_cut_uncorrect_value;

  -- ���� ���� ���� �� ���� ��������, ������� ���������� ��������� � �����,
  -- �� ������
  IF l_cut_uncorrect_value IS NOT NULL THEN
    RAISE ATTR_NOT_CORRECT_VALUE_EXCEPTION;
  END IF;

  -- ���� ��� �������� ���������, �� �������������� ������� �� ������ � �����
  -- � ���������� �������� "�������_"
  l_query :=
    'UPDATE obj_attr_values_1000001 attr SET A_' || l_new_cut ||
    ' = (' ||
        'SELECT to_number(Replace(attr_.A_' || l_old_cut || ', ''.'', '','')) ' ||
        'FROM obj_attr_values_1000001 attr_ ' ||
        'WHERE attr_.soCode = attr.soCode ' ||
        ')' ||
    'WHERE attr.A_' || l_old_cut || ' IS NOT NULL';

--  Dbms_Output.put_line(l_query);

  EXECUTE IMMEDIATE l_query;

  COMMIT;

EXCEPTION
  WHEN ATTR_NOT_EXISTS_EXCEPTION THEN
    Raise_Application_Error(
      -20101, '�� ������ �������!');
  WHEN ATTR_NOT_CORRECT_VALUE_EXCEPTION THEN
    Raise_Application_Error(
      -20102, '������������ �������� ��������: ' || l_cut_uncorrect_value);
END;
/