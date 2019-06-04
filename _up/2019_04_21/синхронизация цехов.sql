-- цеха на ТП
SELECT DISTINCT
  f_value
FROM
  sepo_tp_fields
WHERE
    Lower(field_name) LIKE '%ceh%';

-- синхронизация цехов
-- tp_workshop - цех, указанный в файле
-- subst_workshop - цех-заменитель
-- substr_section - участок-заменитель
SELECT
  *
FROM
  sepo_tp_workshops_subst;

-- если в первом запросе есть цеха, которых нет в втором запросе,
-- то выгружай в файлик, я добавлю в таблицу