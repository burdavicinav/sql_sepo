-- ������ ����������� ��������

-- ��������
SELECT * FROM sepo_std_folders;
-- ���� ���������
SELECT * FROM sepo_std_folder_codes;
-- ���� ������
SELECT * FROM sepo_std_fields;
-- �������
SELECT * FROM sepo_std_tables;
-- ������
SELECT * FROM sepo_std_records;
-- ���������� ������
SELECT * FROM sepo_std_record_contents;
-- ���� ������
SELECT * FROM sepo_std_table_fields;
-- ������ ������
SELECT * FROM sepo_std_table_records;
-- ���������� ������� ������
SELECT * FROM sepo_std_table_rec_contents;
-- �������� ������������
SELECT * FROM sepo_std_enum_folders;
-- ������������
SELECT * FROM sepo_std_enum_list;
-- ���������� �����������
SELECT * FROM sepo_std_enum_contents;
-- �����
SELECT * FROM sepo_std_schemes;
-- �������
SELECT * FROM sepo_std_formulas;
-- ��������� ��
SELECT * FROM sepo_std_tp_params;

-- ����� (�� ���������)
SELECT * FROM v_sepo_std_schemes_build;
-- ������ ���������
SELECT * FROM v_sepo_std_attr_properties;
-- "�������" ��������
SELECT * FROM v_sepo_std_simple_attrs;
-- ��������-������������
SELECT * FROM v_sepo_std_list_attrs;
-- �������� ����
SELECT * FROM v_sepo_std_attrs;
-- ����� (��� �������������)
SELECT * FROM v_sepo_std_schemes;
-- �������
SELECT * FROM v_sepo_std_tables;
-- ������� ��������
SELECT * FROM v_sepo_std_expressions;
-- ��������� �� �� ����������� ��������
SELECT * FROM v_sepo_std_tp_params;
-- ����� �� � ����������� ���������
SELECT * FROM v_sepo_std_tp_params_link;
-- ���������� ���� ���������
SELECT DISTINCT f_entermode FROM sepo_std_table_fields;

-- ��������-������������
SELECT
  *
FROM
  sepo_std_table_fields
WHERE
    f_entermode = 'IEM_LIST';

-- "������������" ��������
SELECT
  *
FROM
  sepo_std_table_fields
WHERE
    f_entermode = 'IEM_ASPARENT';

-- �������� ����
SELECT
  *
FROM
  sepo_std_table_rec_contents
WHERE
    regexp_like(field_value, '^\d+[\.,]\d+$');

-- ������������� ��������
WITH class(id, f_key, f_owner, f_level, f_name, lvl) AS
(
  SELECT
    id,
    f_key,
    f_owner,
    f_level,
    f_name,
    0
  FROM
    sepo_std_folders
  WHERE
      f_owner = 0

  UNION ALL

  SELECT
    f.id,
    f.f_key,
    f.f_owner,
    f.f_level,
    f.f_name,
    c.lvl + 1
  FROM
    class c,
    sepo_std_folders f
  WHERE
      f.f_owner = c.f_level
)
search depth first BY f_level SET orderval
SELECT
  c.*,
  LPad(' ', 4 * c.lvl) || ' ' || c.f_name
FROM
  class c
ORDER BY
  orderval;

-- �������� ��������� "��������"
SELECT
  c.*
FROM
  sepo_std_table_fields f,
  sepo_std_enum_list l,
  sepo_std_enum_contents c
WHERE
    f.enm_owner = l.f_key
  AND
    Upper(f_longname) = '��������'
  AND
    c.id_enum = l.id;

SELECT
  omp_name,
  omp_type,
  id_enum,
  enum_name
FROM
  v_sepo_std_attrs
WHERE
    omp_name LIKE '%��������%'
GROUP BY
  omp_name,
  omp_type,
  id_enum,
  enum_name;

-- ������ - �������� �� ����� 597 �� ��
SELECT
  *
FROM
  v_sepo_std_attrs
WHERE
    tname LIKE '%597'
ORDER BY
  tname,
  Upper(omp_name);

-- ������� � ���������� ������������ (f_descr)
SELECT
  f_descr,
  Count(DISTINCT id)
FROM
  sepo_std_tables
GROUP BY
  f_descr
HAVING
  Count(DISTINCT id) > 1;

-- ����� � ���������� �������������
-- � ����� ������������ ����������� "-T<����� �������>"
SELECT
  *
FROM
  v_sepo_std_schemes
WHERE
    scheme_name LIKE '%-T%';

-- ������������ ����� �� ����������� � 100 ��������
-- � �������� ������������ ����������� ����� �������
SELECT
  *
FROM
  sepo_std_schemes
WHERE
    f_level = 3726
  AND
    istable = 1;

-- �������
SELECT * FROM sepo_std_tables t, sepo_std_table_records r
WHERE
    r.id_table = t.id
  AND
    NOT EXISTS (
      SELECT 1 FROM sepo_std_table_fields f
      WHERE
          f.id_table = t.id
        AND
          f.f_longname = '������ ������������'
    );

SELECT
  t.*,
  f.*
  --regexp_substr(f_data, '\{.?\[?F\d+\]?\}', 1, 4)
FROM
  sepo_std_tables t,
  sepo_std_table_fields f
WHERE
    f.id_table = t.id
  AND
    f.f_longname = '������ ������������';

SELECT * FROM v_sepo_std_formuls r
WHERE
    NOT EXISTS (
      SELECT 1 FROM sepo_std_table_fields f
      WHERE
          r.field = f.field
    )
  AND
    EXISTS (
      SELECT 1 FROM
        sepo_std_records pr,
        sepo_std_record_contents prc,
        sepo_std_fields f
      WHERE
          pr.id_table = r.id
        AND
          prc.id_record = pr.id
        AND
          f.id = prc.id_field
        AND
          r.field = f.field
    );

SELECT
  t.id AS id_table,
  t.f_key AS tblkey,
  t.f_table,
  s.id_record,
  pr.f_key AS reckey,
  r.f_key AS trkey,
  f.id AS id_field,
  f.field,
  f.f_longname,
  f.f_shortname,
  f.f_entermode,
  f.f_data,
  s.field_value
FROM
  sepo_std_fixture_to_tp_tools s,
  sepo_std_table_fields f,
  sepo_std_table_records r,
  sepo_std_tables t,
  sepo_std_records pr
WHERE
    s.id_field = f.id
  AND
    s.id_record = r.id
  AND
    r.id_table = t.id
  AND
    pr.id_table = t.id
  AND
    f.f_longname = '������ ������������'
  AND
    f_data LIKE '%[%]%'
--  AND
--    field_value LIKE '%~%'
--  AND
--    EXISTS (
--      SELECT
--        1
--      FROM
--        sepo_std_expressions_temp e
--      WHERE
--          e.id_record = s.id_record
--        AND
--          e.field_mode = 'IEM_EXPRESSION'
--    )
--  AND
--    id_record = 604739;
ORDER BY
  To_Number(regexp_replace(t.f_table, '\D', '')),
  r.f_key;

EXEC pkg_sepo_import_global.buildstandardschemes();
EXEC pkg_sepo_import_global.parsingstdfixformuls();
EXEC pkg_sepo_import_global.importstdgosts(93, 6308);
EXEC pkg_sepo_import_global.setstdfixobjparams();
EXEC pkg_sepo_import_global.setoldfixobjparams();
EXEC pkg_sepo_import_global.createstdclassify('3726', 4, 3726);
EXEC pkg_sepo_import_global.createstdclassify('4208', 4, 4208);
EXEC pkg_sepo_import_global.createoldfixtureclassify('3709', 4, 3709);

DECLARE

BEGIN
  FOR i IN (
    SELECT * FROM sepo_import_triggers_disable WHERE id_task = 18
  ) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_name || ' disable';
  END LOOP;

  pkg_sepo_import_global.loadstdfixture(218, 93, 106, 120);

  FOR i IN (
    SELECT * FROM sepo_import_triggers_disable WHERE id_task = 18
  ) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_name || ' enable';
  END LOOP;

END;
/

DECLARE

BEGIN
  FOR i IN (
    SELECT * FROM sepo_import_triggers_disable WHERE id_task = 9
  ) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_name || ' disable';
  END LOOP;

  pkg_sepo_import_global.loadoldfixture(218, 93, 106, 115);

  FOR i IN (
    SELECT * FROM sepo_import_triggers_disable WHERE id_task = 9
  ) LOOP
    EXECUTE IMMEDIATE 'alter trigger ' || i.trigger_name || ' enable';
  END LOOP;

END;
/


SELECT * FROM fixture_types;
SELECT * FROM owner_name;
SELECT * FROM measures;
SELECT * FROM businessobj_states
WHERE
    botype = 32;

SELECT * FROM sepo_std_tech_attrs_temp;

SELECT * FROM obj_attributes
WHERE
    objtype = 33
  AND
    shortname IN ('RecKey', 'TBLKey', 'Table', '�_��');

SELECT socode, a_9368, a_9369, a_9367, a_9370 FROM obj_attr_values_33;


SELECT * FROM v_sepo_std_attrs
WHERE
    f_entermode = 'IEM_LIST';

SELECT
        i.lvl_type,
        i.id_record,
        i.reckey,
        i.tblkey,
        i.f_table,
        i.name,
        i.sign_vo,
        c.key_ AS lvlkey,
        t.code AS typecode,
        i.scheme_name,
        v.code AS scheme_code
      FROM
        v_sepo_std_import i,
        sepo_std_folder_codes c,
        fixture_types t,
        obj_enumerations e,
        obj_enumerations_values v,
        sepo_std_table_rec_contents rc
      WHERE
          i.lvl_classify = 3726
        AND
          c.id_folder = i.lvl_type
        AND
          c.name = t.name
        AND
          e.name = '@���_��������'
        AND
          v.encode = e.code
        AND
          v.shortname = i.scheme_name
        AND
          rc.id_record = i.id_record
--        AND
--          rc.id_field = 202201
      ORDER BY
        reckey,
        tblkey