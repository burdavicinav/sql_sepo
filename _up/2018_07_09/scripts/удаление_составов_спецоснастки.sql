SELECT DISTINCT k1.itemtype FROM specifications s, konstrobj k, konstrobj k1
WHERE
    s.spccode = k.unvcode
  AND
    s.code = k1.unvcode
  AND
    k.itemtype = 31;

DELETE FROM specifications
WHERE
    spccode IN (
      SELECT unvcode FROM konstrobj
      WHERE
          itemtype = 31
    );