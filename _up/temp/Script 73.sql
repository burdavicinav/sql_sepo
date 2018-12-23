SELECT * FROM v_sepo_std_formuls ORDER BY id, ind;

SELECT
  Upper(f_longname),
  Max(f_shortname)
FROM
  sepo_std_table_fields
WHERE
    f_entermode = 'IEM_EXPRESSION'
GROUP BY
  Upper(f_longname);

SELECT
  DISTINCT Lower(f.f_longname)
FROM
  sepo_std_table_fields f
WHERE
    f.f_entermode = 'IEM_EXPRESSION'
  AND
    EXISTS (
      SELECT 1 FROM sepo_std_table_fields f_
      WHERE
          f_.f_entermode != 'IEM_EXPRESSION'
        AND
          f_.f_longname = f.f_longname
    );

EXEC pkg_sepo_import_global.setstdfixobjparams();

DECLARE
  l_ind NUMBER;
  l_pos NUMBER;
  l_left VARCHAR2(100);
  l_right VARCHAR2(100);
  l_str VARCHAR2(1000) := '{F1} {F9}-{F10} ÊË. ÒÎ×ÍÎÑÒÈ {F11} {F3}';
  l_exp VARCHAR2(100) := '\{.?\[?F\d+\]?\}|\[[^]F]*\]';
  k NUMBER;
  n NUMBER;

  TYPE strlist IS TABLE OF VARCHAR2(100);
  l_tokens strlist;

BEGIN
  n := 0;

  FOR i IN (
    SELECT
      f_data
    FROM
      sepo_std_table_fields
    WHERE
        f_entermode = 'IEM_EXPRESSION'
  ) LOOP
    n := n + 1;
    l_str := i.f_data;

    Dbms_Output.put_line(n || ' base_str: ' || l_str);
    l_tokens := strlist();

    k := 0;
    LOOP
      k := k + 1;
--      Dbms_Output.put_line('k = ' || k);

      l_pos := regexp_instr(l_str, l_exp);
  --    Dbms_Output.put_line('pos = ' || l_pos);

      IF l_pos IS NULL OR l_pos = 0 THEN

        IF l_str IS NOT NULL THEN
          l_tokens.extend();
          l_tokens(l_tokens.Count()) := l_str;

        END IF;

        EXIT;

      ELSE
        l_left := '';
        l_right := '';

        IF l_pos > 1 THEN
          l_left := SubStr(l_str, 1, l_pos - 1);

          l_tokens.extend();
          l_tokens(l_tokens.Count()) := l_left;

        END IF;

        l_right := regexp_substr(l_str, l_exp);

        l_tokens.extend();
        l_tokens(l_tokens.Count()) := l_right;

        l_str := SubStr(
          l_str,
          l_pos + Length(l_right),
          Length(l_str) - (l_pos + Length(l_right) - 1)
          );

      END IF;

--      Dbms_Output.put_line('left: ' || l_left);
--      Dbms_Output.put_line('right: ' || l_right);
--      Dbms_Output.put_line('str: ' || l_str);

  --    IF (k > 10) THEN EXIT; END IF;

    END LOOP;

--    FOR i IN 1..l_tokens.Count() LOOP
--      Dbms_Output.put_line(l_tokens(i));

--    END LOOP;

  END LOOP;

END;
/