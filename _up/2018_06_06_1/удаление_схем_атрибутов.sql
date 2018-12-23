DELETE FROM obj_types_schemes
WHERE
    name LIKE '@%';

DECLARE

BEGIN
  FOR i IN (
    SELECT
      *
    FROM
      obj_attributes
    WHERE
        objtype = 33
      AND
        To_Char(code) = shortname
  ) LOOP
    pkg_sepo_system_objects.dropattr(33, i.shortname);

  END LOOP;

END;
/

SELECT * FROM obj_types_schemes
WHERE
    name LIKE '@%';

SELECT * FROM obj_attributes
WHERE
    objtype = 33
  AND
    To_Char(code) = shortname
  AND
    name = 'дхюлерп оняюднвмнцн нрбепярхъ';