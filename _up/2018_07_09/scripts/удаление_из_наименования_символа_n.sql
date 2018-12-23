BEGIN
  -- ����� �� ���������
  UPDATE business_objects b SET b.checkout = -2
  WHERE
      b.TYPE IN (2, 31, 32, 33)
    AND
      EXISTS (
        SELECT
          1
        FROM
          konstrobj k
        WHERE
            k.unvcode = b.doccode
          AND
            regexp_like(k.name, '\\n')
    );

  -- ���� ������ "\n" � ����� ������������, �� ������� ���
  UPDATE konstrobj
  SET
    name = regexp_replace(name, '(\\n)+$', '')
  WHERE
      regexp_like(name, '(\\n)+$');

  -- ���� ������ "\n" ������ ������������, �� �������� �� ������
  UPDATE konstrobj
  SET
    name = regexp_replace(name, '\\n[^$]', ' ')
  WHERE
      regexp_like(name, '\\n[^$]');

  -- ������ ���������
  UPDATE business_objects b SET b.checkout = NULL
  WHERE
      b.TYPE IN (2, 31, 32, 33)
    AND
      b.checkout = -2;

END;
/