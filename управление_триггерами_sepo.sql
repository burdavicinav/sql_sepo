SELECT * FROM dba_objects
WHERE
    object_type = 'TRIGGER'
  AND
    object_name LIKE '%SEPO%';

DECLARE

BEGIN
  FOR i IN (
    SELECT * FROM dba_objects
    WHERE
        object_type = 'TRIGGER'
      AND
        object_name LIKE '%SEPO%'
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER TRIGGER ' || i.object_name || ' DISABLE';
  END LOOP;
END;
/

BEGIN
  FOR i IN (
    SELECT * FROM dba_objects
    WHERE
        object_type = 'TRIGGER'
      AND
        object_name LIKE '%SEPO%'
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER TRIGGER ' || i.object_name || ' ENABLE';
  END LOOP;
END;
/

SELECT Count(*) FROM konstrobj;

SELECT * FROM omp_properties
WHERE
    code = 106;