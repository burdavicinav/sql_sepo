--SELECT * FROM obj_attributes WHERE objtype = 1000090;
--SELECT * FROM obj_attr_values_1000090;

DECLARE
  l_horizon_code NUMBER;
  l_unionlot_code NUMBER;
  l_maxcount_code NUMBER;

  -- горизонт объединения ДСЕ в партию
  l_horizon_value NUMBER := 60;
  -- объединять ДСЕ в одну партию по всему заказу (0 или 1)
  l_unionlot_value NUMBER := 1;
  -- максимальное количество ДСЕ в одной партии
  l_maxcount_value NUMBER := 30;

BEGIN
  l_horizon_code := pkg_sepo_attr_operations.getcode(1000090, 'ГоризонтОбъед');
  l_unionlot_code := pkg_sepo_attr_operations.getcode(1000090, 'ОбъедЗаказ');
  l_maxcount_code := pkg_sepo_attr_operations.getcode(1000090, 'МаксПартия');

  EXECUTE IMMEDIATE
    'update obj_attr_values_1000090 set ' ||
    'a_' || l_horizon_code || ' = :p1,' ||
    'a_' || l_unionlot_code || ' = :p2,' ||
    'a_' || l_maxcount_code  || ' = :p3'
  USING
    l_horizon_value,
    l_unionlot_value,
    l_maxcount_value;

  COMMIT;

END;
/