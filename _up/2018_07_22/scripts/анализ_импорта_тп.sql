-- ���������� ��������� �������

-- �� ��� �������� � ���
SELECT
  *
FROM
  sepo_tech_processes t
WHERE
    NOT EXISTS (
      SELECT
        1
      FROM
        sepo_tp_to_dce d
      WHERE
          d.id_tp = t.id
    )
ORDER BY
  t.designation;

-- ����������� ��� � ��
SELECT
  *
FROM
  sepo_tech_processes t,
  sepo_tp_to_dce d
WHERE
    d.id_tp = t.id
  AND
    NOT EXISTS (
      SELECT
        1
      FROM
        bo_production b,
        ko_types k
      WHERE
          k.code = b.TYPE
        AND
          b.Sign = d.designation
    )
ORDER BY
  t.designation;

-- �� ��� ��������
SELECT
  *
FROM
  sepo_tech_processes t
WHERE
    NOT EXISTS (
      SELECT
        1
      FROM
        sepo_tp_opers o
      WHERE
          o.id_tp = t.id
    )
ORDER BY
  t.designation;

-- ����������� �������� � ��������������
SELECT
  t.id,
  t.key_ AS tpkey,
  t.designation AS tpsign,
  op.key_ AS opkey,
  op.reckey AS reckey,
  op.order_,
  op.num
FROM
  sepo_tp_opers op,
  sepo_tech_processes t
WHERE
    op.id_tp = t.id
  AND
    NOT EXISTS (
      SELECT
        1
      FROM
        technology_operations top
      WHERE
          top.description = op.reckey
    )
ORDER BY
  t.designation,
  op.num;

-- � �������� �� ��� ������
SELECT
  *
FROM
  sepo_tech_processes t,
  v_sepo_tp_opers o
WHERE
    o.id_tp = t.id
  AND
    num IS NULL;

-- ����� ������ �������� ������ 4
SELECT
  *
FROM
  v_sepo_tp_opers
WHERE
    Length(num) > 4;

-- �� ������ ������������ ����
SELECT
  t.*,
  f.field_name,
  f.f_value
FROM
  sepo_tp_fields f,
  sepo_tp_exclude_authors a,
  sepo_tech_processes t
WHERE
    f.f_value = a.author
  AND
    field_name IN ('���', '���1')
  AND
    t.id = f.id_tp
ORDER BY
  t.designation;

-- �������� � ���������� �������� � ���������/�������� ��
SELECT
  *
FROM
  v_sepo_tech_processes_base
WHERE
    kind = 1
  AND
    dce_cnt > 1;

-- �� ������ ��� � ����������� �������������
-- 5000 �� 40000 �������� - �� ������ ���,
-- ���� �� ����������� ������������ � ������������ � �����
SELECT
  t.id,
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  o.key_,
  o.reckey,
  o.num,
  o.opername,
  o.cex,
  o.wscode
FROM
  sepo_tech_processes t,
  v_sepo_tp_opers o
WHERE
    o.id_tp = t.id
  AND
    wscode IS NULL
ORDER BY
  t.designation;

-- ��� ��������� � �����������
SELECT
  *
FROM
  v_sepo_tp_workers w,
  sepo_tp_opers o,
  sepo_tech_processes t
WHERE
    w.operkey = o.key_
  AND
    t.id = o.id_tp
  AND
    w.ompcode IS NULL;

-- � ����������� ��� ���������
SELECT
  *
FROM
  v_sepo_tp_workers w,
  sepo_tp_opers o,
  sepo_tech_processes t
WHERE
    w.operkey = o.key_
  AND
    t.id = o.id_tp
  AND
    category IS NULL;

-- �� ������� ������ ������������ � �����������
SELECT
  *
FROM
  v_sepo_tp_equipments e,
  sepo_tp_opers o,
  sepo_tech_processes t
WHERE
    e.operkey = o.key_
  AND
    t.id = o.id_tp
  AND
    e.ompcode IS NULL;

-- ��� ��������� � ��������������
SELECT
  *
FROM
  v_sepo_tp_steps s,
  sepo_tp_opers o,
  sepo_tech_processes t
WHERE
    o.key_ = s.operkey
  AND
    t.id = o.id_tp
  AND
    s.ompcode IS NULL;

-- ����������� ��������� ����� � ��������
-- ����� ��������� 94840
-- ��� ����������� ������ ����� 16000
SELECT
  *
FROM
  v_sepo_tp_steps s,
  sepo_tp_opers o,
  sepo_tech_processes t
WHERE
    o.key_ = s.operkey
  AND
    t.id = o.id_tp
  AND
    s.stepnumber IS NULL
ORDER BY
  t.designation,
  o.num;

-- ����� ������������ (3709) � ���������� ��, ����� ����������
-- objtype = null - ����� ���
SELECT
  objtype,
  Count(DISTINCT t.id)
FROM
  v_sepo_tp_tools t
  left JOIN
  v_sepo_fixture_attrs a
  ON
      a.o_vo = t.o_vo
    AND
      a.objtype IN (31,32)
WHERE
    t.catalog = 3709
GROUP BY
  a.objtype;

-- ����������� ������������, 3709
-- ����������� �� ��������� �_��
SELECT
  a.id,
  a.id_tp,
  a.operkey,
  a.perehkey,
  a.key_,
  a.order_,
  a.catalog,
  a.tp_reckey,
  a.tp_tblkey,
  a.tp_vo,
  a.norm,
  a.socode,
  a.objtype,
  a.art_id,
  a.table_,
  a.tblkey,
  a.reckey,
  a.o_vo,
  a.unvcode,
  a.Sign AS ksign,
  a.name AS kname,
  b.num AS opernum,
  t.designation,
  t.doc_id
FROM
  (
  SELECT
    t.id,
    t.id_tp,
    t.operkey,
    t.perehkey,
    t.key_,
    t.order_,
    t.catalog,
    t.reckey AS tp_reckey,
    t.tblkey AS tp_tblkey,
    t.o_vo AS tp_vo,
    t.norm AS norm,
    a.socode,
    a.objtype,
    a.art_id,
    a.table_,
    a.tblkey,
    a.reckey,
    a.o_vo,
    k.unvcode,
    k.Sign,
    k.name,
    Row_Number() OVER (
      PARTITION BY t.id
      ORDER BY
        CASE
          WHEN k.Sign NOT LIKE '%��' THEN 0
          ELSE 1
        END,
        CASE
          WHEN a.o_vo = k.Sign THEN 0
          ELSE 1
        END,
        a.objtype
      ) AS num
  FROM
    v_sepo_tp_tools t
    left JOIN
    v_sepo_fixture_attrs a
    ON
        a.o_vo = t.o_vo
      AND
        a.objtype IN (31, 32)
    left JOIN
    konstrobj k
    ON
        k.bocode = a.socode
  WHERE
      t.catalog = 3709
  ) a,
  sepo_tp_opers b,
  sepo_tech_processes t
WHERE
    a.operkey = b.key_
  AND
    t.id = b.id_tp
  AND
    a.num = 1
  AND
    socode IS NULL
ORDER BY
  t.designation,
  b.num;

-- ����������� ������ ������������ (4046, 4143, 4208)
-- 42894 ������ �����
-- 9730 ������� �� �������
-- ����������� �� tp_tblkey, tp_reckey, ������������ ��������

SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.catalog,
  t.reckey AS tp_reckey,
  t.tblkey AS tp_tblkey,
  t.norm,
  t.o_vo AS tp_vo,
  o.socode,
  o.objtype,
  o.art_id,
  o.table_,
  o.tblkey,
  o.reckey,
  o.o_vo,
  o.unvcode,
  o.ksign,
  o.kname,
  op.num AS opernum,
  t.designation,
  t.doc_id
FROM
  v_sepo_tp_tools t
  JOIN
  sepo_tp_opers op
  ON
      t.operkey = op.key_
  JOIN
  sepo_tech_processes t
  ON
      t.id = op.id_tp
  left JOIN
  (
    SELECT
      a.socode,
      a.objtype,
      a.table_,
      a.tblkey,
      a.reckey,
      a.o_vo,
      a.art_id,
      k.unvcode,
      k.Sign AS ksign,
      k.name AS kname,
      n.id_tool,
      n.name
    FROM
      v_sepo_fixture_attrs a
      JOIN
      konstrobj k
      ON
          k.bocode = a.socode
      left JOIN
      v_sepo_std_formula_names n
      ON
          n.reckey = a.reckey
        AND
          n.tblkey = a.tblkey
        AND
          n.name = k.name
        AND
          n.f_longname = '������������ ��� ��'
  ) o
  ON
      t.reckey = o.reckey
    AND
      t.tblkey = o.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog IN (4046, 4143, 4208)
  AND
    o.socode IS NULL
ORDER BY
  t.designation,
  op.num;

-- ����������� ����������� ��������
-- ����������� �� tp_tblkey, tp_reckey, ������������ ��������
-- ����� ������� 91645
-- �� ������� ����� 5000
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.catalog,
  t.reckey AS tp_reckey,
  t.tblkey AS tp_tblkey,
  t.o_vo AS tp_vo,
  t.norm,
  o.socode,
  o.objtype,
  o.art_id,
  o.table_,
  o.tblkey,
  o.reckey,
  o.o_vo,
  o.unvcode,
  o.ksign,
  o.kname,
  op.num AS opernum,
  t.designation,
  t.doc_id
FROM
  v_sepo_tp_tools t
  JOIN
  sepo_tp_opers op
  ON
      t.operkey = op.key_
  JOIN
  sepo_tech_processes t
  ON
      t.id = op.id_tp
  left JOIN
  (
    SELECT
      a.socode,
      a.objtype,
      a.table_,
      a.tblkey,
      a.reckey,
      a.o_vo,
      a.art_id,
      k.unvcode,
      k.Sign AS ksign,
      k.name AS kname,
      n.id_tool,
      n.name
    FROM
      v_sepo_fixture_attrs a
      JOIN
      konstrobj k
      ON
          k.bocode = a.socode
      left JOIN
      v_sepo_std_formula_names n
      ON
          n.reckey = a.reckey
        AND
          n.tblkey = a.tblkey
        AND
          n.name = k.name
        AND
          n.f_longname = '������ ������������'
  ) o
  ON
      t.reckey = o.reckey
    AND
      t.tblkey = o.tblkey
    AND
      t.id = coalesce(o.id_tool, t.id)
WHERE
    t.catalog NOT IN (3709, 4046, 4143, 4208)
  AND
    o.socode IS NULL
ORDER BY
  t.designation,
  op.num;