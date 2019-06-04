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

SELECT * FROM documents_params WHERE code = 8642;
SELECT * FROM documents_parts WHERE code = 8642;

UPDATE documents_params SET HASH = NULL, hash_alg = NULL WHERE code = 8642;

b3d0c6de541c1d28810fe0a8fdfd07f014460dac
182d40490a3364d2125f13e79bc7e597b9cd09f0
0039c24be6c941d9ca43effc48708e768b177f13
903123BFAD730EFF0430211435B7DEEC03C7E71A

SELECT * FROM documents_parts WHERE num = 2;