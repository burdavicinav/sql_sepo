CREATE TABLE sepo_dbf_load (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100) NOT NULL,
  file_ VARCHAR2(100) NOT NULL,
  date_ DATE DEFAULT SYSDATE NOT NULL,
  notice VARCHAR2(1000) NULL
);

INSERT INTO sepo_dbf_load
VALUES
(1, '�������� ���������� �� FoxPro', 'MATERS.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    '�������������� �������� ����������'
    );

INSERT INTO sepo_dbf_load
VALUES
(2, '�������� ���� ������� �� FoxPro', 'PSHIMUK.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    '�������������� �������� ����'
    );

INSERT INTO sepo_dbf_load
VALUES
(3, '�������� ��������� �� FoxPro', 'FAIL2.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    '�������������� �������� ���������'
    );

INSERT INTO sepo_dbf_load
VALUES
(4, '�������� ���������� �� FoxPro', 'MATERS.DBF',
  SYSDATE, '������� �� ��� � ���������'
  );

INSERT INTO sepo_dbf_load
VALUES
(5, '�������� ���� ������� �� FoxPro', 'PSHIMUK.DBF',
  SYSDATE, '����������� ����������'
  );

ALTER TABLE sepo_maters ADD id_load NUMBER NULL
  REFERENCES sepo_dbf_load(id);

ALTER TABLE sepo_pshimuk ADD id_load NUMBER NULL
  REFERENCES sepo_dbf_load(id);

ALTER TABLE sepo_fail2 ADD id_load NUMBER NULL
  REFERENCES sepo_dbf_load(id);

UPDATE sepo_maters SET id_load = 1;
UPDATE sepo_pshimuk SET id_load = 2;
UPDATE sepo_fail2 SET id_load = 3;

-- ���������� �������� � ������� ���� � �����
-- ����� �� ��������� �������� ��� ������� �� 1000
ALTER TABLE sepo_pshimuk MODIFY chv NUMBER(13,6);
ALTER TABLE sepo_pshimuk MODIFY nr NUMBER(14,6);

COMMIT;