CREATE OR REPLACE DIRECTORY DBF_DIR AS 'C:\Servers\Oracle\app\oracle\oradata\omega\dbf';
GRANT WRITE ON DIRECTORY DBF_DIR TO omp_adm;

SELECT * FROM dba_directories;

DECLARE
  V1 VARCHAR2(32000);
  F1 Utl_File.FILE_TYPE;
BEGIN
  F1 := Utl_File.FOPEN('DBF_DIR','test.txt','W',256);
  --Utl_File.Get_line(F1,V1, 256);
  Utl_File.FCLOSE(F1);

  Dbms_Output.put_line(V1 || '1');
END;
/

CREATE TABLE test
(
  id blob
);

SELECT * FROM test;

--

CREATE OR REPLACE TRIGGER tbi_test
BEFORE INSERT ON test
FOR EACH ROW

DECLARE
  V1 VARCHAR2(256);
  F1 Utl_File.FILE_TYPE;

  b BLOB;
  c CLOB;
  r RAW(10);
  r1 RAW(100);

  length_ NUMBER;

  binary_number BINARY_INTEGER;
  number_ FLOAT(4);
BEGIN
--  number_ := 3;
--  r := Utl_Raw.cast_from_number(number_);
  binary_number := 3;
  r := Utl_Raw.cast_from_binary_integer(binary_number);
  length_ := Utl_Raw.Length(r);

  r1 := Utl_Raw.cast_to_raw('ывапывап');
  Dbms_Output.put_line(Utl_Raw.Length(r1));


  Dbms_Lob.createtemporary(b, TRUE, Dbms_Lob.CALL);
  Dbms_Lob.OPEN(b, Dbms_Lob.LOB_READWRITE);

  Dbms_Lob.WRITE(b, 4, 1, r);
--  r := UTL_RAW.convert(r,'AMERICAN_AMERICA.CL8MSWIN1251','AMERICAN_AMERICA.CL8MSWIN1251');
--  Dbms_Lob.WRITE(b,Utl_Raw.Length(r1),5,r1);


  F1 := Utl_File.FOPEN('DBF_DIR','test.dbf','wb');
--  Utl_File.put_raw(F1,r);
--  Utl_File.put_raw(F1,r1);
  Utl_File.put_raw(F1,b);
  --Utl_File.Get_line(F1,V1, 256);
  Utl_File.FCLOSE(F1);
--  Dbms_Lob.freetemporary(b);

END;
/

INSERT INTO test
VALUES
(1);

SELECT *
FROM nls_database_parameters