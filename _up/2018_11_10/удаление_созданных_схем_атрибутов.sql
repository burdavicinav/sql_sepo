UPDATE obj_attributes SET shortname = regexp_replace(shortname, '\D', '')
WHERE
    code IN (10530, 10536, 10548);

BEGIN
  FOR i IN (
    SELECT
      code,
      name
    FROM
      obj_types_schemes
    WHERE
        objtype = 33
      AND
        InStr(name, '@') = 1

  ) LOOP
    pkg_sepo_system_objects.dropscheme(33, i.name);
    COMMIT;

  END LOOP;

END;
/

BEGIN
  FOR i IN (
    SELECT
      shortname
    FROM
      obj_attributes
    WHERE
        objtype = 33
      AND
        regexp_like(shortname, '^\d+$')

  ) LOOP
    pkg_sepo_system_objects.dropattr(33, i.shortname);
    COMMIT;

  END LOOP;

END;
/

SELECT DISTINCT f_entermode FROM v_sepo_std_attrs;
SELECT * FROM sepo_std_attrs;
SELECT * FROM v_sepo_std_tp_params;

SELECT
  id_table,
  id
      FROM
        sepo_std_table_fields
      WHERE
          f_entermode = 'IEM_EXPRESSION'
      GROUP BY
        Upper(f_longname)