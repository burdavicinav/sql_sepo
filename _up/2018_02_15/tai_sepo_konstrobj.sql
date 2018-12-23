CREATE OR REPLACE TRIGGER tai_sepo_konstrobj
AFTER INSERT ON konstrobj
DECLARE
  l_count NUMBER;
BEGIN
  SELECT
    Count(1)
  INTO
    l_count
  FROM
    konstrobj ko,
    sepo_konstrobj_temp tmp
  WHERE
      ko.Sign != tmp.Sign
    AND
      ko.itemtype = tmp.itemtype
    AND
      regexp_replace(Lower(tmp.Sign), '\W|_', '') =
        regexp_replace(Lower(ko.Sign), '\W|_', '');

  IF l_count > 0 THEN
    Raise_Application_Error(
      -20102,
      'Нарушение уникальности обозначения элемента!'
    );
  END IF;

  DELETE FROM sepo_konstrobj_temp;

END;
/