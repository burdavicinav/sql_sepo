SELECT
  data.userId,
  u.fullName,
  data.month_,
  Round(Sum(( data.logoutDate - data.loginDate ) * 24), 3) AS cntHours
FROM
  (
  SELECT
    code,
    userId,
    To_Char(execDate, 'YYYY.MM') AS month_,
    execDate AS loginDate,
    To_Date(
      SubStr(
        reportTitle,
        InStr(reportTitle, 'logout', 1, 1) + Length('logout') + 1,
        Length(reportTitle) - InStr(reportTitle, 'logout', 1, 1) + 1
        ),
      'DD.MM.YYYY HH24:MI:SS'
      ) AS logoutDate
  FROM
    eventlog log
  WHERE
      okEnd = 1
    AND
      className LIKE '''Login'''
  ) data,
  user_list u
WHERE
    u.code = data.userId
  AND
    u.code != -2
  AND
    data.loginDate >= To_Date('01.07.2017', 'DD.MM.YYYY')
GROUP BY
  data.userId,
  u.fullName,
  data.month_
ORDER BY
  data.month_,
  u.fullName;