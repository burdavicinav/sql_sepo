PROMPT CREATE OR REPLACE VIEW v_sepo_tp_opers
CREATE OR REPLACE VIEW v_sepo_tp_opers (
  id_op,
  id_tp,
  key_,
  reckey,
  order_,
  date_,
  num,
  place,
  tpkey,
  opercode,
  opername,
  cex,
  subcex,
  instruction,
  remark,
  topcode,
  wscode,
  seccode,
  secsign,
  koid,
  koid_num,
  dopname
) AS
SELECT
  op.id AS id_op,
  op.id_tp,
  op.key_,
  op.reckey,
  op.order_,
  op.date_,
  op.num,
  op.place,
  op.tpkey,
  f1.f_value AS opercode,
  f2.f_value AS opername,
  f3.f_value AS cex,
  sub.subst_workshop AS subcex,
  f4.f_value AS instruction,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  top.code AS topcode,
  w.code AS wscode,
  sc.code AS seccode,
  sc.Sign AS secsign,
  f5.f_value AS koid,
  CASE
    WHEN regexp_like(f5.f_value, '^[-]?\d+([\.,]\d+)?$')
      THEN To_Number(REPLACE(f5.f_value, ',', '.'))
    ELSE 1
  END koid_num,
  f6.f_value AS dopname
FROM
  sepo_tp_opers op
  left JOIN
  sepo_tp_oper_comments c
  ON
      c.id_oper = op.id
  left JOIN
  sepo_tp_oper_fields f1
  ON
      f1.id_oper = op.id
    AND
      f1.field_name = ' ÓÔÍ'
  left JOIN
  sepo_tp_oper_fields f2
  ON
      f2.id_oper = op.id
    AND
      f2.field_name = 'Œœ≈–'
  left JOIN
  sepo_tp_oper_fields f3
  ON
      f3.id_oper = op.id
    AND
      f3.field_name = '÷≈’'
  left JOIN
  sepo_tp_oper_fields f4
  ON
      f4.id_oper = op.id
    AND
      f4.field_name = ' _Ú·'
  left JOIN
  sepo_tp_oper_fields f5
  ON
      f5.id_oper = op.id
    AND
      f5.field_name = ' Œ»ƒ'
  left JOIN
  sepo_tp_oper_fields f6
  ON
      f6.id_oper = op.id
    AND
      f6.field_name = 'ƒÓÔ'
  left JOIN
  technology_operations top
  ON
      top.description = To_Char(op.reckey)
  left JOIN
  sepo_tp_workshops_subst sub
  ON
      f3.f_value = sub.tp_workshop
  left JOIN
  divisionobj d
  ON
      d.division_type IN (104, 701)
    AND
      d.wscode = coalesce(sub.subst_workshop, f3.f_value)
  left JOIN
  workshops w
  ON
      w.dobjcode = d.code
  left JOIN
  divisionobj ds
  ON
      ds.wscode = sub.subst_section
  left JOIN
  sections sc
  ON
      sc.dobjcode = ds.code;