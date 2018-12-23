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
    business_objects bo,
    businessobj_states bs,
    businessobj_promotion_levels lvl,
    sepo_konstrobj_temp tmp
  WHERE
      bo.code = ko.bocode
    AND
      bs.code = bo.today_state
    AND
      lvl.code = bs.promlevel
    AND
      ko.Sign != tmp.Sign
    AND
      lvl.name NOT LIKE 'Аннул%'
--    AND
--      ko.itemtype = tmp.itemtype
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