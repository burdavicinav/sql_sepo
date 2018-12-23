CREATE SEQUENCE sq_sepo_pshimuk
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  INCREMENT BY 1
  NOCYCLE
  NOORDER
  CACHE 20
/


CREATE TABLE sepo_pshimuk
(
  "ID" NUMBER,
  "SHI" NUMBER(7,0),
  "SHD" NUMBER(17,0),
  "PRD" NUMBER(2,0),
  "SHM" NUMBER(7,0),
  "PRM" NUMBER(1,0),
  "PRI" NUMBER(8,3),
  "CEX" NUMBER(3,0),
  "ED" NUMBER(2,0),
  "NR" NUMBER(11,3),
  "CHV" NUMBER(10,3),
  "DCE" VARCHAR2(18),
  "TABN" NUMBER(4,0),
  "DATAVK" VARCHAR2(10)
);

--DROP TABLE sepo_pshimuk;

CREATE OR REPLACE TRIGGER tbi_sepo_pshimuk
BEFORE INSERT ON sepo_pshimuk
FOR EACH ROW
DECLARE

BEGIN
  IF :new.id IS NULL THEN :new.id := sq_sepo_pshimuk.NEXTVAL; END IF;

END;
/

CREATE TABLE sepo_import_pshimuk_log (
  id      NUMBER         NULL,
  message VARCHAR2(1000) NULL,
  logDate DATE DEFAULT SYSDATE
);

--SELECT * FROM sepo_pshimuk;

-- анонимный блок создает представление, которое
-- объединяет поле ДСЕ со всех объектов системы
DECLARE
  l_attr_2 NUMBER;
  l_attr_3 NUMBER;
  l_attr_5 NUMBER;

  sqlQuery VARCHAR2(300);

BEGIN
  SELECT
    code
  INTO
    l_attr_2
  FROM
    obj_attributes
  WHERE
      name = 'DCE'
    AND
      objType = 2;

  SELECT
    code
  INTO
    l_attr_3
  FROM
    obj_attributes
  WHERE
      name = 'DCE'
    AND
      objType = 3;

  SELECT
    code
  INTO
    l_attr_5
  FROM
    obj_attributes
  WHERE
      name = 'DCE'
    AND
      objType = 5;

  sqlQuery :=
  'CREATE OR REPLACE VIEW view_sepo_union_attrs_dce AS ' ||
    'SELECT ' ||
      'soCode,' ||
      'value_ ' ||
    'FROM ' ||
      '(' ||
      'SELECT soCode, A_' || l_attr_2 || ' AS value_ FROM obj_attr_values_2 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_3 || ' AS value_ FROM obj_attr_values_3 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_5 || ' AS value_ FROM obj_attr_values_5 ' ||
    ')';

  EXECUTE IMMEDIATE sqlQuery;

END;
/

-- основной запрос, участвующий в импорте
-- связывает sepo_pshimuk c омеговскими кодами ДСЕ и материала
CREATE OR REPLACE VIEW view_sepo_pshimuk
AS
SELECT
  data.*,
  bo.code AS dceSoCode,
  ko.unvCode AS dceCode,
  ko.itemType AS dceType,
  mats.soCode AS matSoCode,
  mats.code AS matCode
FROM
  sepo_pshimuk data,
  view_sepo_union_attrs_dce dce,
  business_objects bo,
  konstrobj ko,
  materials mats
WHERE
    data.dce = dce.value_(+)
  AND
    dce.soCode = bo.code(+)
  AND
    bo.docCode = ko.unvCode(+)
  AND
    data.shm = mats.plCode(+);