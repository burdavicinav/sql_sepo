DECLARE
  l_sql VARCHAR2(1000);
  TYPE tp_attr_list IS TABLE OF NUMBER INDEX BY VARCHAR2(10);
  l_attrs tp_attr_list;
BEGIN
  l_attrs.DELETE();
  FOR i IN (
    SELECT * FROM obj_attributes
    WHERE
        objType = 2
      AND
        shortName IN ('ART_ID', 'SECTION_ID')
  ) LOOP
    l_attrs(i.shortName) := i.code;
  END LOOP;

  l_sql := 'create or replace view v_sepo_search_omega_link as ' ||
    'select ' ||
    'bo.code as bocode,' ||
    'attr_2.A_' || l_attrs('ART_ID') || ' as art_id,' ||
    'attr_2.A_' || l_attrs('SECTION_ID') || ' as section_id ' ||
    'from ' ||
    'business_objects bo,' ||
    'obj_attr_values_2 attr_2 ' ||
    'where bo.code = attr_2.socode union all ';

  l_attrs.DELETE();
  FOR i IN (
    SELECT * FROM obj_attributes
    WHERE
        objType = 31
      AND
        shortName IN ('ART_ID', 'SECTION_ID')
  ) LOOP
    l_attrs(i.shortName) := i.code;
  END LOOP;

  l_sql := l_sql ||
    'select ' ||
    'bo.code as bocode,' ||
    'attr_31.A_' || l_attrs('ART_ID') || ' as art_id,' ||
    'attr_31.A_' || l_attrs('SECTION_ID') || ' as section_id ' ||
    'from ' ||
    'business_objects bo,' ||
    'obj_attr_values_31 attr_31 ' ||
    'where bo.code = attr_31.socode union all ';

  l_attrs.DELETE();
  FOR i IN (
    SELECT * FROM obj_attributes
    WHERE
        objType = 32
      AND
        shortName IN ('ART_ID', 'SECTION_ID')
  ) LOOP
    l_attrs(i.shortName) := i.code;
  END LOOP;

  l_sql := l_sql ||
    'select ' ||
    'bo.code as bocode,' ||
    'attr_32.A_' || l_attrs('ART_ID') || ' as art_id,' ||
    'attr_32.A_' || l_attrs('SECTION_ID') || ' as section_id ' ||
    'from ' ||
    'business_objects bo,' ||
    'obj_attr_values_32 attr_32 ' ||
    'where bo.code = attr_32.socode';

  EXECUTE IMMEDIATE l_sql;
END;
/

CREATE OR REPLACE VIEW v_sepo_fixture_docs
AS
SELECT
  l.art_id,
  l.bocode,
  a.doc_id,
  d.filename
FROM
  sepo_osn_all a,
  v_sepo_search_omega_link l,
  sepo_osn_docs d
WHERE
    a.art_id = l.art_id
  AND
    d.doc_id = a.doc_id
  AND
    a.doc_id != -2
GROUP BY
  l.art_id,
  l.bocode,
  a.doc_id,
  d.filename;