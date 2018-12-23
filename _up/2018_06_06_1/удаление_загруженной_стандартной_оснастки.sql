-- ��������! ���������� ���� ������� ���������
-- ����� ���������� ��������� ������ ���������
BEGIN
  DELETE FROM sepo_triggers_for_disable;

  INSERT INTO sepo_triggers_for_disable (
    trigger_
  )
  SELECT
    trigger_name
  FROM
    dba_triggers
  WHERE
      trigger_name NOT LIKE '%SEPO%'
    AND
      status = 'ENABLED'
    AND
      owner = 'OMP_ADM';

  -- ���������� ���������
  FOR i IN (SELECT trigger_ FROM sepo_triggers_for_disable) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_ || ' disable';
  END LOOP;

  -- �������� ����������� ����������� ��������
  pkg_sepo_import_global.deletestdfixture();

  -- ��������� ���������
  FOR i IN (SELECT trigger_ FROM sepo_triggers_for_disable) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_ || ' enable';
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    FOR i IN (SELECT trigger_ FROM sepo_triggers_for_disable) LOOP
      EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_ || ' enable';
    END LOOP;

    RAISE;

END;
/