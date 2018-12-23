-- построение представления view_sepo_union_attrs_dce
-- осуществляет связь поля DCE из файла с кодом объекта
-- в Омеге

DECLARE
  l_attr_1 NUMBER;
  l_attr_2 NUMBER;
  l_attr_3 NUMBER;
  l_attr_4 NUMBER;
  l_attr_5 NUMBER;
  l_attr_22 NUMBER;

  sqlQuery VARCHAR2(500);

BEGIN
  SELECT
    code
  INTO
    l_attr_1
  FROM
    obj_attributes
  WHERE
      name = 'DCE'
    AND
      objType = 1;

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
    l_attr_4
  FROM
    obj_attributes
  WHERE
      name = 'PKI'
    AND
      objType = 4;

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

  SELECT
    code
  INTO
    l_attr_22
  FROM
    obj_attributes
  WHERE
      name = 'DCE'
    AND
      objType = 22;

  sqlQuery :=
  'CREATE OR REPLACE VIEW view_sepo_union_attrs_dce AS ' ||
    'SELECT ' ||
      'soCode,' ||
      'value_ ' ||
    'FROM ' ||
      '(' ||
      'SELECT soCode, A_' || l_attr_1 || ' AS value_ FROM obj_attr_values_1 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_2 || ' AS value_ FROM obj_attr_values_2 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_3 || ' AS value_ FROM obj_attr_values_3 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_4 || ' AS value_ FROM obj_attr_values_4 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_5 || ' AS value_ FROM obj_attr_values_5 ' ||
      'UNION ' ||
      'SELECT soCode, A_' || l_attr_22 || ' AS value_ FROM obj_attr_values_22 ' ||
    ')';

  EXECUTE IMMEDIATE sqlQuery;

END;
/

/* последовательность для таблицы импорта */
CREATE SEQUENCE sq_sepo_fail2
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  INCREMENT BY 1
  NOCYCLE
  NOORDER
  CACHE 20
/

/* создание таблицы импорта fail2 */
/* содержит 24 цеха */
/* в другом файле может быть другое количество цехов */
DECLARE
  sqlQuery VARCHAR2(2000);
BEGIN
  sqlQuery :=
    'CREATE TABLE sepo_fail2' ||
    '(' ||
    '"ID" NUMBER,' ||
    '"FILENAME" VARCHAR2(100),' ||
    '"DCE" VARCHAR2(18),' ||
    '"PRIZM" NUMBER(1,0),' ||
    '"OCEX" NUMBER(3,0),';

  FOR i IN 1..24 LOOP
    sqlQuery := sqlQuery ||
      '"CEX' || i || '" NUMBER(3,0),' ||
      '"PKM' || i || '" NUMBER(1,0),' ||
      '"CIKL' || i || '" NUMBER(3,0),';

  END LOOP;

  sqlQuery := sqlQuery ||
    '"DATV" VARCHAR2(10),' ||
    '"DATD" VARCHAR2(10),' ||
    '"PPP" NUMBER(1,0)' ||
    ')';

--  Dbms_Output.put_line(sqlQuery);
  EXECUTE IMMEDIATE sqlQuery;

END;
/
ALTER TABLE sepo_fail2 ADD PRIMARY KEY(id);

/* триггер заполняет первичный ключ */
CREATE OR REPLACE TRIGGER tbi_sepo_fail2
BEFORE INSERT ON sepo_fail2
FOR EACH ROW
DECLARE

BEGIN
  IF :new.id IS NULL THEN :new.id := sq_sepo_fail2.NEXTVAL; END IF;

END;
/

/* последовательность для состава маршрута из файла импорта */
CREATE SEQUENCE sq_sepo_fail2_routes
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  INCREMENT BY 1
  NOCYCLE
  NOORDER
  CACHE 20
/

/* таблица для состава маршрута из файла импорта */
CREATE TABLE sepo_fail2_routes
(
  id NUMBER PRIMARY KEY,
  id_fail2 NUMBER NOT NULL REFERENCES sepo_fail2(id),
  number_ NUMBER NOT NULL,
  cex NUMBER NOT NULL
);

/* триггер для заполнения значения первичного ключа */
CREATE OR REPLACE TRIGGER tbi_sepo_fail2_routes
BEFORE INSERT ON sepo_fail2_routes
FOR EACH ROW
DECLARE

BEGIN
  IF :new.id IS NULL THEN :new.id := sq_sepo_fail2_routes.NEXTVAL; END IF;

END;
/

/* лог */
CREATE TABLE sepo_import_fail2_log (
  id      NUMBER         NULL,
  message VARCHAR2(1000) NULL,
  logDate DATE DEFAULT SYSDATE
);

/* связь цеха из файла с пунктами маршрута Омеги */
CREATE TABLE sepo_cex_to_district
(
  cexCode NUMBER,
  districtCode NUMBER
);

/* представление для детализации маршрута из файла */
CREATE OR REPLACE VIEW view_sepo_fail2_data
AS
SELECT
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  data.cex1 AS firstDistrict,
  items_max.cex AS endDistrict,
  listagg(items.cex,';') within GROUP (ORDER BY items.number_)
    AS routeString,
  dce.soCode,
  bo.docCode
FROM
  sepo_fail2 data,
  sepo_fail2_routes items,
  sepo_fail2_routes items_max,
  view_sepo_union_attrs_dce dce,
  business_objects bo
WHERE
    data.id = items.id_fail2
  AND
    data.id = items_max.id_fail2
  AND
    items_max.number_ = (
      SELECT Max(items_.number_) FROM sepo_fail2_routes items_
      WHERE
          items_.id_fail2 = items_max.id_fail2
    )
  AND
    data.dce = dce.value_(+)
  AND
    dce.soCode = bo.code(+)
GROUP BY
  data.id,
  data.fileName,
  data.dce,
  data.prizm,
  data.ocex,
  data.cex1,
  items_max.cex,
  dce.soCode,
  bo.docCode;

-- представление для импорта
-- не включается ДСЕ, которые отсутствуют в Омеге
-- не включаются пустые маршруты и маршруты,
-- в которых указан только один пункт маршрута

-- имя файла для импорта "fail2.dbf"
CREATE OR REPLACE VIEW view_sepo_fail2_import
AS
SELECT
  data.id,
  data.fileName,
  data.dce,
  coalesce(data.prizm, 0) AS prizm,
  coalesce(data.ocex, 0) AS ocex,
  datv,
  datd,
  ppp,
  dce.soCode,
  bo.docCode,
  bo.TYPE AS docType,
  spec.spcCode,
  coalesce(spec.cntNum,1) AS cntnum,
  coalesce(spec.cntDenom,1) AS cntDenom
FROM
  sepo_fail2 data,
  view_sepo_union_attrs_dce dce,
  business_objects bo,
  specifications spec
WHERE
    fileName LIKE 'fail2.dbf'
  AND
    data.cex2 > 0
  AND
    data.dce = dce.value_
  AND
    dce.soCode = bo.code
  AND
    bo.docCode = spec.code(+);