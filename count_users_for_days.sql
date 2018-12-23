SELECT
  To_Date(To_Char(execDate, 'DD.MM.YYYY'), 'DD.MM.YYYY') AS day_,
  Count(DISTINCT userId) AS cntUsers
FROM
  eventLog
WHERE
    execDate >= To_Date('01.07.2017', 'DD.MM.YYYY')
GROUP BY
  To_Date(To_Char(execDate, 'DD.MM.YYYY'), 'DD.MM.YYYY')
ORDER BY
  To_Date(To_Char(execDate, 'DD.MM.YYYY'), 'DD.MM.YYYY');