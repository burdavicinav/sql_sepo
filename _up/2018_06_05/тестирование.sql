--ALTER TABLE plan_table MODIFY object_name VARCHAR2(32);

DELETE FROM sepo_std_schemes;

-- ãåíåðàöèÿ íàèìåíîâàíèÿ îñíàñòêè
EXEC pkg_sepo_import_global.buildstandardschemes();

DECLARE
  l_scheme VARCHAR2(200);
BEGIN
  FOR i IN (
    SELECT b.* FROM v_sepo_std_schemes_build b
  ) LOOP
    l_scheme := i.scheme;

    pkg_sepo_import_global.getstdschemename(i.f_name, i.tbl_descr, i.scheme);
    Dbms_Output.put_line(l_scheme);

  END LOOP;

END;
/

-- ðàçäåëåíèå ñòðîêè íà ñëîâà
WITH f(str, pos, pos_num, sub_str)
AS
(
  SELECT
    str || ' ',
    InStr(str, ' ', 1, 1),
    1,
    SubStr(str, 1, InStr(str, ' ', 1, 1) - 1)
  FROM
    (
    SELECT
      'ÐÅÆÓÙÈÉ ÈÍÑÒÐÓÌÅÍÒ ÑÂÅÐËÀ ÑÏÈÐÀËÜÍÛÅ Ñ ÊÎÍÈ×ÅÑÊÈÌ ÕÂÎÑÒÎÂÈÊÎÌ ÃÎÑÒ 12121-77 (ÄËÈÍÍÛÅ)' AS str
    FROM
      dual
    )
  UNION ALL
  SELECT
    str,
    InStr(str, ' ', 1, pos_num + 1),
    pos_num + 1,
    SubStr(str, pos + 1, InStr(str, ' ', 1, pos_num + 1) - (pos + 1))
  FROM
    f
  WHERE
      InStr(str, ' ', 1, pos_num + 1) > 0
)
SELECT
  *
FROM
  f;