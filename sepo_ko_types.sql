--DROP TABLE sepo_ko_types;

CREATE TABLE sepo_ko_types
(
  id NUMBER NOT NULL,
  name VARCHAR2(50) NOT NULL,
  id_bo_type NUMBER REFERENCES businessobj_types(code)
    ON DELETE SET NULL,

  UNIQUE(id, id_bo_type)
);

-- ��������� ���������
INSERT INTO sepo_ko_types
VALUES
(8, '��������� ��������', 5);

-- ����������� �������
INSERT INTO sepo_ko_types
VALUES
(5, '����������� �������', 3);

-- ������
INSERT INTO sepo_ko_types
VALUES
(4, '������', 2);

-- ��������� ����
INSERT INTO sepo_ko_types
VALUES
(3, '��������� ����', 1);

-- ���������
INSERT INTO sepo_ko_types
VALUES
(3, '���������', 22);

COMMIT;