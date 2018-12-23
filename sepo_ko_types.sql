--DROP TABLE sepo_ko_types;

CREATE TABLE sepo_ko_types
(
  id NUMBER NOT NULL,
  name VARCHAR2(50) NOT NULL,
  id_bo_type NUMBER REFERENCES businessobj_types(code)
    ON DELETE SET NULL,

  UNIQUE(id, id_bo_type)
);

-- сборочные материалы
INSERT INTO sepo_ko_types
VALUES
(8, 'Сборочный материал', 5);

-- стандартные изделия
INSERT INTO sepo_ko_types
VALUES
(5, 'Стандартное изделие', 3);

-- детали
INSERT INTO sepo_ko_types
VALUES
(4, 'Детали', 2);

-- сборочные узлы
INSERT INTO sepo_ko_types
VALUES
(3, 'Сборочные узлы', 1);

-- комплекты
INSERT INTO sepo_ko_types
VALUES
(3, 'Комплекты', 22);

COMMIT;