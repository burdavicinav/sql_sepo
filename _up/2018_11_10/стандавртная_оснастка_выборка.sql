SELECT
  t_33.a_9369,
  t_33.a_9368,
  t_33.a_12602,
  t_33.a_10953,
  k.Sign,
  k.name,
  k.bocode
FROM
  konstrobj k,
  obj_attr_values_33 t_33
WHERE
    k.itemtype = 33
  AND
    t_33.socode = k.bocode
--  AND
--    k.Sign = '8136-01/68(+0,2)H13'
ORDER BY
  name,
  t_33.a_9368,
  t_33.a_9369;