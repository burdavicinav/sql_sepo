CREATE GLOBAL TEMPORARY TABLE sepo_konstrobj_temp (
  unvcode NUMBER,
  itemtype NUMBER,
  Sign VARCHAR2(200),
  name VARCHAR2(200),
  revision NUMBER,
  prodcode NUMBER
) ON COMMIT PRESERVE ROWS;