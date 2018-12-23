CREATE SEQUENCE sq_sepo_maters
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  INCREMENT BY 1
  NOCYCLE
  NOORDER
  CACHE 20
/

CREATE TABLE sepo_maters (
"ID" NUMBER PRIMARY KEY,
"MAT" NUMBER(7,0),
"SKL" NUMBER(3,0),
"CEN" NUMBER(11,2),
"DATA" VARCHAR2(20),
"POZ1" NUMBER(4,0),
"POZ2" NUMBER(4,0),
"EIO" NUMBER(3,0),
"GRU" NUMBER(7,0),
"NAIM" VARCHAR2(20),
"MARK" VARCHAR2(20),
"DIAM" VARCHAR2(2),
"DM" NUMBER(10,3),
"CLT" NUMBER(1,0),
"TOL" NUMBER(10,3),
"CHIR" NUMBER(10,3),
"DL" NUMBER(10,3),
"GOST" VARCHAR2(30),
"SORM" VARCHAR2(25),
"KOEF" NUMBER(4,2),
"EID1" NUMBER(3,0),
"UDN1" NUMBER(8,3),
"EID2" NUMBER(3,0),
"UDN2" NUMBER(8,3),
"VED" NUMBER(2,0),
"PRNOM" NUMBER(1,0),
"CENN" NUMBER(11,2),
"SROKX" NUMBER(2,0),
"PRES" VARCHAR2(20),
"PRESB" VARCHAR2(20),
"OKP" NUMBER(11,0),
"TABN" NUMBER(4,0),
"PRIS" NUMBER(1,0),
"SER" NUMBER(13,7),
"ZOL" NUMBER(13,7),
"ROD" NUMBER(13,7),
"PAL" NUMBER(13,7),
"PLAT" NUMBER(13,7),
"PLAT_IR" NUMBER(13,7),
"ZVET" VARCHAR2(10),
"SORT" VARCHAR2(10),
"CENX" NUMBER(11,2),
"PRESX" VARCHAR2(15),
"PPVK" NUMBER(1,0),
"VPR" NUMBER(1,0),
"OBOZNGR" VARCHAR2(1),
"KODGR" NUMBER(1,0),
"DATV" VARCHAR2(20),
"DKOR" VARCHAR2(20),
"TABKOR" NUMBER(7,0),
"OKEI" NUMBER(5,0),
"IMP" NUMBER(1,0),
"ORG" VARCHAR2(100),
"RUT" NUMBER(13,7),
"CENGZ" NUMBER(11,2),
"PRESGZ" VARCHAR2(15)
);

CREATE OR REPLACE TRIGGER tbi_sepo_maters
BEFORE INSERT ON sepo_maters
FOR EACH ROW
DECLARE

BEGIN
  IF :new.id IS NULL THEN :new.id := sq_sepo_maters.NEXTVAL; END IF;

END;
/

CREATE TABLE sepo_shm_list
(
  shm NUMBER
);

CREATE TABLE sepo_units
(
  code NUMBER,
  group_ VARCHAR2(121),
  name VARCHAR2(121),
  shortName VARCHAR2(21),
  codeBNM NUMBER,
  codeEKON NUMBER,
  codeSAP NUMBER,
  weight VARCHAR2(121),
  isBase NUMBER,
  is_si NUMBER
);

CREATE TABLE sepo_import_maters_log
(
  id NUMBER,
  message VARCHAR2(1000)
);