-- всего переходов в ТП
SELECT Count(*) FROM steps_for_operation;

-- часто исаользуемые переходы
SELECT
--  name,
  regexp_substr(Trim(name), '^[^ ]+( +[^ ]+){0,3}') AS step,
  Count (DISTINCT code) AS cnt
FROM
  steps_for_operation
WHERE
    name IS NOT NULL
GROUP BY
  regexp_substr(Trim(name), '^[^ ]+( +[^ ]+){0,3}')
ORDER BY
  Count (DISTINCT code) DESC;