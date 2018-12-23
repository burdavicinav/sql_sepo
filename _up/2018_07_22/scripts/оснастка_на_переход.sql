-- техпроцессы
SELECT * FROM v_sepo_tech_processes WHERE designation LIKE '7Д5.752.001%';

-- операции на ТП
SELECT * FROM v_sepo_tp_opers WHERE id_tp = 37927 AND key_ = 925523;

-- переходы на операцию
SELECT * FROM v_sepo_tp_steps WHERE operkey = 925523 973587;

-- оснастка
SELECT * FROM v_sepo_tp_tools WHERE id_tp = 37927 AND operkey = 862734;