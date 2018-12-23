SELECT
  b.TYPE,
  Count(b.code)
FROM
  attachments a
  JOIN
  business_objects b
  ON
      b.code = a.businessobj
WHERE
    a.hint IS NULL
GROUP BY
  b.TYPE;

UPDATE attachments a
SET
  hint = 0
WHERE
    a.hint IS NULL;