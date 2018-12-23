INSERT INTO sepo_dbf_load
(id, name, file_, date_, notice)
VALUES
(6, 'Загрузка смесей из FoxPro', 'LIT.DBF', SYSDATE, NULL);

CREATE SEQUENCE sq_sepo_lit;

CREATE TABLE sepo_lit (
  id NUMBER PRIMARY KEY,
  id_load NUMBER NULL,
  shm NUMBER(7,0) NOT NULL,
  shk NUMBER(7,0) NOT NULL,
  nr NUMBER(10,3) NULL,
  prc NUMBER(7,3) NULL
);

CREATE OR REPLACE TRIGGER tbi_sepo_lit
BEFORE INSERT ON sepo_lit
FOR EACH ROW
DECLARE

BEGIN
  IF :new.id IS NULL THEN :new.id := sq_sepo_lit.NEXTVAL; END IF;
END;
/