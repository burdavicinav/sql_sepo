CREATE TABLE sepo_dbf_load (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(100) NOT NULL,
  file_ VARCHAR2(100) NOT NULL,
  date_ DATE DEFAULT SYSDATE NOT NULL,
  notice VARCHAR2(1000) NULL
);

INSERT INTO sepo_dbf_load
VALUES
(1, 'Загрузка материалов из FoxPro', 'MATERS.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    'Первоначальная загрузка материалов'
    );

INSERT INTO sepo_dbf_load
VALUES
(2, 'Загрузка норм расхода из FoxPro', 'PSHIMUK.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    'Первоначальная загрузка норм'
    );

INSERT INTO sepo_dbf_load
VALUES
(3, 'Загрузка маршрутов из FoxPro', 'FAIL2.DBF',
    To_Date('04.07.2017', 'DD.MM.YYYY'),
    'Первоначальная загрузка маршрутов'
    );

INSERT INTO sepo_dbf_load
VALUES
(4, 'Загрузка материалов из FoxPro', 'MATERS.DBF',
  SYSDATE, 'Перенос из ТМЦ в материалы'
  );

INSERT INTO sepo_dbf_load
VALUES
(5, 'Загрузка норм расхода из FoxPro', 'PSHIMUK.DBF',
  SYSDATE, 'Обновленный справочник'
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

-- увеличение точности у чистого веса и нормы
-- чтобы не пропадала точность при делении на 1000
ALTER TABLE sepo_pshimuk MODIFY chv NUMBER(13,6);
ALTER TABLE sepo_pshimuk MODIFY nr NUMBER(14,6);

COMMIT;