-- ������� ������� ������ ������ - ������ ���� ����
SELECT
  *
FROM
  dba_constraints
WHERE
    table_name = 'SEPO_TFLEX_OBJ_SYNCH'
  AND
    constraint_type = 'U';

-- ������ ���� 3 �������: TFLEX_SECTION, TFLEX_DOCSIGN, OMP_BOTYPE
SELECT
  c.constraint_name,
  c.column_name
FROM
  dba_cons_columns c
  JOIN
  dba_constraints cs
  ON
      cs.constraint_name = c.constraint_name
WHERE
    cs.table_name = 'SEPO_TFLEX_OBJ_SYNCH'
  AND
    cs.constraint_type = 'U';

-- ���� ���-�� �� ���, �� ���������
BEGIN
  FOR i IN (
    SELECT
      constraint_name
    FROM
      dba_constraints
    WHERE
        table_name = 'SEPO_TFLEX_OBJ_SYNCH'
      AND
        constraint_type = 'U'

  ) LOOP
    EXECUTE IMMEDIATE 'alter table sepo_tflex_obj_synch drop constraint '
      || i.constraint_name;

  END LOOP;

END;