-- �����������
SELECT * FROM v_sepo_tech_processes WHERE designation LIKE '7�5.752.001%';

-- �������� �� ��
SELECT * FROM v_sepo_tp_opers WHERE id_tp = 37927 AND key_ = 925523;

-- �������� �� ��������
SELECT * FROM v_sepo_tp_steps WHERE operkey = 925523 973587;

-- ��������
SELECT * FROM v_sepo_tp_tools WHERE id_tp = 37927 AND operkey = 862734;