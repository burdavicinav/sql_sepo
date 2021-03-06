PROMPT CREATE OR REPLACE PACKAGE exporttodbf
CREATE OR REPLACE PACKAGE exporttodbf
IS
  -- ������������ ���������
  CP866 CONSTANT NUMBER := 1;
  WIN1251 CONSTANT NUMBER := 2;

  -- ����� �������� �����
  STR_MODE_DEFAULT NUMBER := 1;
  STR_MODE_UPPER NUMBER := 2;

  -- ������� ����
  NULL_BYTE CONSTANT RAW(1) := utl_raw.cast_to_raw(Chr(0));
  -- ����� �����
  END_FILE CONSTANT RAW(1) := Utl_Raw.cast_to_raw(Chr(26));

  -- ������������� ��������
  PROCEDURE InizializeDBF(
    p_dir VARCHAR2,
    p_file VARCHAR2,
    p_str_mode NUMBER := STR_MODE_DEFAULT,
    p_charset NUMBER := CP866
  );

  -- ������������� �����
  PROCEDURE InizializeColumns;

  -- �������� ����
  PROCEDURE AddColumn(
    p_name VARCHAR2,
    p_type CHAR,
    p_full_length BINARY_INTEGER,
    p_decimal_length BINARY_INTEGER
  );

  PROCEDURE DataBeginWrite;

  PROCEDURE DataEndWrite;

  PROCEDURE NewRecord;

  -- �������� �������� ����
  PROCEDURE AddField(
    p_field NUMBER,
    p_amount NUMBER,
    p_decimal NUMBER := 0 );

  PROCEDURE AddField(
    p_field VARCHAR2,
    p_amount NUMBER );

  PROCEDURE AddField(
    p_field DATE );

  -- �������� ������ � ����
  PROCEDURE AppendData;

  -- ����� � ����� (4 �����)
  FUNCTION GetBytes(
    p_number BINARY_INTEGER,
    p_count_bytes NUMBER
    )
  RETURN RAW;

  -- ������ � ����� � ������������ ��������������� ���������
  FUNCTION GetBytes(
    p_str VARCHAR2,
    p_is_convert BOOLEAN DEFAULT FALSE,
    p_cs_old NUMBER DEFAULT WIN1251,
    p_cs_new NUMBER DEFAULT CP866)
  RETURN RAW;

  -- ���� � �����
  FUNCTION GetBytes(
    p_date DATE
  )
  RETURN RAW;

  -- ������� ����� � ������ � ������ ��� DBF �������
  FUNCTION NumberToString(
    p_number NUMBER,
    p_length NUMBER,
    p_decimal NUMBER DEFAULT 0
  )
  RETURN VARCHAR2;

  -- ���������� ��������
  PROCEDURE Write(p_blob IN OUT BLOB, p_raw RAW);

  -- �������
  PROCEDURE Export;

  FUNCTION CountRecords RETURN NUMBER;

END;
/

PROMPT CREATE OR REPLACE PACKAGE BODY exporttodbf
CREATE OR REPLACE PACKAGE BODY exporttodbf
IS
  -- ����������
  pkg_dir VARCHAR2(100);
  -- ��� �����
  pkg_file VARCHAR2(100);
  -- ���������� �������
  pkg_cnt_recs BINARY_INTEGER;
  -- ������ �����
  pkg_data BLOB;
  -- ����� �������� �����
  pkg_str_mode NUMBER;
  -- ���������
  pkg_charset NUMBER;

  -- ��������� ��������� ���� ����� DBF
  TYPE DBFColumn IS RECORD (
    name VARCHAR2(11),
    type_ CHAR,
    full_length BINARY_INTEGER,
    decimal_length BINARY_INTEGER
  );

  -- ��������� ��������
  TYPE DBFColumns IS TABLE OF DBFColumn;
  cols DBFColumns;

  -- ������������� DBF
  -- ������������� ���������� � ��� �����
  PROCEDURE InizializeDBF(
    p_dir VARCHAR2,
    p_file VARCHAR2,
    p_str_mode NUMBER := STR_MODE_DEFAULT,
    p_charset NUMBER := CP866
  )
  IS
  BEGIN
    pkg_dir := p_dir;
    pkg_file := p_file;
    pkg_str_mode := p_str_mode;
    pkg_charset := p_charset;
    pkg_data := NULL;
    pkg_cnt_recs := 0;
  END;

  -- ������������� ��������� ��������
  -- �������� ������
  PROCEDURE InizializeColumns
  IS

  BEGIN
    cols := DBFColumns();
  END;

  -- ���������� �������
  PROCEDURE AddColumn(
    p_name VARCHAR2,
    p_type CHAR,
    p_full_length BINARY_INTEGER,
    p_decimal_length BINARY_INTEGER
  )
  IS
    l_column DBFColumn;
  BEGIN
    l_column.name := p_name;
    l_column.type_ := p_type;
    l_column.full_length := p_full_length;
    l_column.decimal_length := p_decimal_length;

    cols.extend();
    cols(cols.Count) := l_column;
  END;

  FUNCTION GetRawFromNumber(
    p_number NUMBER,
    p_length NUMBER,
    p_decimal NUMBER DEFAULT 0
    )
  RETURN RAW
  IS
    l_str VARCHAR2(100);
  BEGIN
    l_str := NumberToString(p_number, p_length, p_decimal);

    RETURN GetBytes(
        l_str,
        TRUE,
        WIN1251,
        pkg_charset);
  END;

  FUNCTION GetRawFromString(
    p_str VARCHAR2,
    p_length NUMBER
    )
  RETURN RAW
  IS
  BEGIN
    RETURN GetBytes(
        RPad(Nvl(p_str, ' '), p_length),
        TRUE,
        WIN1251,
        pkg_charset);
  END;

  FUNCTION GetRawFromDate(
    p_date DATE
    )
  RETURN RAW
  IS
  BEGIN
    IF p_date IS NULL THEN
      RETURN Utl_Raw.cast_to_raw(RPad(' ', 8));
    ELSE
      RETURN GetBytes(
          To_Char(p_date, 'YYYYMMDD'),
          TRUE,
          WIN1251,
          pkg_charset);

    END IF;

  END;

  PROCEDURE DataBeginWrite
  IS

  BEGIN
    Dbms_Lob.createtemporary(pkg_data, TRUE);
    Dbms_Lob.OPEN(pkg_data, Dbms_Lob.LOB_READWRITE);

    pkg_cnt_recs := 0;
  END;

  PROCEDURE DataEndWrite
  IS

  BEGIN
    NULL;
  END;

  PROCEDURE NewRecord
  IS

  BEGIN
    Write(pkg_data, Utl_Raw.cast_to_raw(Chr(32)));
    pkg_cnt_recs := pkg_cnt_recs + 1;
  END;

  -- �������� �������� ����
  PROCEDURE AddField(
    p_field NUMBER,
    p_amount NUMBER,
    p_decimal NUMBER := 0 )
  IS

  BEGIN
    Write(pkg_data, GetRawFromNumber(p_field, p_amount, p_decimal));
  END;

  PROCEDURE AddField(
    p_field VARCHAR2,
    p_amount NUMBER )
  IS
  BEGIN
    IF pkg_str_mode = STR_MODE_UPPER THEN
      Write(pkg_data, GetRawFromString(Upper(p_field), p_amount));
    ELSE
      Write(pkg_data, GetRawFromString(p_field, p_amount));

    END IF;

  END;

  PROCEDURE AddField(
    p_field DATE )
  IS

  BEGIN
    Write(pkg_data, GetRawFromDate(p_field));
  END;

  -- ���������� ������
  PROCEDURE AppendData
  IS
    F1 Utl_File.FILE_TYPE;

    l_dbfFile BFILE;
    l_blobFile BLOB;

    l_amount INTEGER;

    l_year RAW(1);
    l_month RAW(1);
    l_day RAW(1);

    l_cnt_raw RAW(4);
    l_records BINARY_INTEGER;

    l_bytes NUMBER;
    l_blob_length NUMBER;
  BEGIN
    -- �������� ����� � ���������� ������ � �����
    l_dbfFile := BFileName(pkg_dir, pkg_file);
    Dbms_Lob.OPEN(l_dbfFile);

    -- �������� ������
    Dbms_Lob.createtemporary(l_blobFile, TRUE);
    -- ������� �����
    Dbms_Lob.OPEN(l_blobFile, Dbms_Lob.LOB_READWRITE);

    -- �������� ������ � ����� �� �����
    Dbms_Lob.LoadFromFile(l_blobFile, l_dbfFile, Dbms_Lob.LOBMAXSIZE);

    -- ������� ����
    Dbms_Lob.CLOSE(l_dbfFile);

    -- �������� ���� �������������� ����� ( �� ����������� )
    l_year := GetBytes(extract(YEAR FROM SYSDATE) - 2000, 1);
    l_month := GetBytes(extract(MONTH FROM SYSDATE), 1);
    l_day := GetBytes(extract(DAY FROM SYSDATE), 1);

    Dbms_Lob.WRITE(l_blobFile, 1, 2, l_year);
    Dbms_Lob.WRITE(l_blobFile, 1, 3, l_month);
    Dbms_Lob.WRITE(l_blobFile, 1, 4, l_day);

    -- �������� ���������� ����� � �����
    l_amount := 4;
    dbms_lob.READ(l_blobFile, l_amount, 5, l_cnt_raw);

    l_cnt_raw := Utl_Raw.REVERSE(l_cnt_raw);
    l_records := Utl_Raw.cast_to_binary_integer(l_cnt_raw);
    l_records := l_records + pkg_cnt_recs;

    l_cnt_raw := GetBytes(l_records, 4);
    Dbms_Lob.WRITE(l_blobFile, l_amount, 5, l_cnt_raw);

    l_amount := 1;
    Dbms_Lob.Trim(l_blobFile, Dbms_Lob.GetLength(l_bloBfile) - 1);

    l_bytes := 1;
    WHILE l_bytes < Dbms_Lob.GetLength(pkg_data) LOOP
      l_blob_length := Least(32000, Dbms_Lob.GetLength(pkg_data) - (l_bytes-1));
      Dbms_Lob.WriteAppend(
        l_blobFile,
        l_blob_length,
        Dbms_Lob.SubStr(pkg_data, l_blob_length, l_bytes)
        );
      l_bytes := l_bytes + l_blob_length;

    END LOOP;

    Dbms_Lob.WriteAppend(l_blobFile, 1, END_FILE);

    -- ������� ���� � ���������� ������
    F1 := Utl_File.FOPEN(pkg_dir, pkg_file, 'wb');

    l_bytes := 1;
    WHILE l_bytes < Dbms_Lob.GetLength(l_blobFile) LOOP
      l_blob_length := Least(32000, Dbms_Lob.GetLength(l_blobFile) - (l_bytes-1));
      Utl_File.put_raw(F1, Dbms_Lob.SubStr(l_blobFile, l_blob_length, l_bytes));
      l_bytes := l_bytes + l_blob_length;

    END LOOP;

    Dbms_Lob.freetemporary(pkg_data);
    Dbms_Lob.FreeTemporary(l_blobFile);
    Utl_File.FClose(F1);

  EXCEPTION
    WHEN OTHERS THEN
      IF Utl_File.IS_OPEN(F1) THEN Utl_File.FClose(F1); END IF;
      RAISE;
  END;

  FUNCTION GetBytes(
    p_number BINARY_INTEGER,
    p_count_bytes NUMBER
    )
  RETURN RAW
  IS
    l_raw RAW(4);
  BEGIN
    l_raw := Utl_Raw.REVERSE(Utl_Raw.cast_from_binary_integer(p_number));
    l_raw := Utl_Raw.SubStr(l_raw, 1, p_count_bytes);

    RETURN l_raw;

  END;

  FUNCTION CharsetToDefinition(p_num NUMBER)
  RETURN VARCHAR2
  IS

  BEGIN
    IF p_num = 1 THEN
      RETURN 'AMERICAN_AMERICA.RU8PC866';
    ELSIF p_num = 2 THEN
      RETURN 'AMERICAN_AMERICA.CL8MSWIN1251';
    END IF;
  END;

  FUNCTION GetBytes(
    p_str VARCHAR2,
    p_is_convert BOOLEAN DEFAULT FALSE,
    p_cs_old NUMBER DEFAULT WIN1251,
    p_cs_new NUMBER DEFAULT CP866)
  RETURN RAW
  IS
    l_raw RAW(255);
  BEGIN
    l_raw := Utl_Raw.cast_to_raw(p_str);
    IF p_is_convert THEN
      l_raw := Utl_Raw.Convert(
        l_raw,
        CharsetToDefinition(p_cs_new),
        CharsetToDefinition(p_cs_old)
        );

    END IF;

    RETURN l_raw;
  END;

  FUNCTION GetBytes(
    p_date DATE
  )
  RETURN RAW
  IS
    l_days BINARY_INTEGER;
    l_hours BINARY_INTEGER;
    l_minutes BINARY_INTEGER;
    l_seconds BINARY_INTEGER;
    l_miliseconds BINARY_INTEGER;

    l_date RAW(4);
    l_time RAW(4);
  BEGIN
    IF p_date IS NOT NULL THEN
      l_days := To_Char(p_date, 'J');
      l_hours := To_Char(p_date, 'HH24');
      l_minutes := To_Char(p_date, 'MM');
      l_seconds := To_Char(p_date, 'SS');

      l_miliseconds :=
        l_hours * 3600 * 1000 +
        l_minutes * 60 * 1000 +
        l_seconds * 1000;

      l_date := GetBytes(l_days, 4);
      l_time := GetBytes(l_miliseconds, 4);

      RETURN Utl_Raw.Concat(l_date, l_time);
    END IF;

    RETURN '1';
  END;

  FUNCTION NumberToString(
    p_number NUMBER,
    p_length NUMBER,
    p_decimal NUMBER DEFAULT 0
  )
  RETURN VARCHAR2
  IS
    l_separator NUMBER;
    l_format VARCHAR2(20);

    l_str VARCHAR2(20);
  BEGIN
    IF p_number IS NULL THEN
      RETURN LPad(' ', p_length);

    ELSE
      IF p_decimal > 0 THEN
        l_separator := 1;
      ELSE
        l_separator := 0;
      END IF;

      l_format := RPad('9', p_length - p_decimal - l_separator, '9');
      IF p_decimal > 0 THEN
        l_format := l_format || '.';
        l_format := l_format || LPad('9', p_decimal, '9');
      END IF;

      l_str := Trim(To_Char(p_number, l_format));
      IF Abs(p_number) < 1 THEN
        l_str := '0' || l_str;

      END IF;

      RETURN LPad(l_str, p_length);

    END IF;
  END;

  PROCEDURE Write(p_blob IN OUT BLOB, p_raw RAW)
  IS
  BEGIN
    Dbms_Lob.writeAppend(p_blob, Utl_Raw.Length(p_raw), p_raw);
  END;

  -- ���������
  FUNCTION WriteHeader
  RETURN BLOB
  IS
    l_header BLOB;

    l_sign RAW(1);
    l_year RAW(1);
    l_month RAW(1);
    l_day RAW(1);
    l_records RAW(4);
    l_header_length RAW(2);
    l_record_length RAW(2);
    l_index_mdx RAW(1);
    l_charset RAW(1);

    l_record_length_number BINARY_INTEGER;
  BEGIN
    Dbms_Lob.createtemporary(l_header, TRUE);
    Dbms_Lob.OPEN(l_header, Dbms_Lob.LOB_READWRITE);

    l_sign := GetBytes(3, 1);
    l_year := GetBytes(extract(YEAR FROM SYSDATE) - 2000, 1);
    l_month := GetBytes(extract(MONTH FROM SYSDATE), 1);
    l_day := GetBytes(extract(DAY FROM SYSDATE), 1);
    l_records := GetBytes(pkg_cnt_recs, 4);
    l_header_length := GetBytes(32 + cols.Count * 32 + 1, 2);

    l_record_length_number := 1;
    FOR i IN 1..cols.Count LOOP
      l_record_length_number := l_record_length_number + cols(i).full_length;

    END LOOP;

--    Dbms_Output.put_line(l_record_length_number);

    l_record_length := GetBytes(l_record_length_number, 2);
    l_index_mdx := GetBytes(0, 1);
    l_charset := GetBytes(101, 1);

    Dbms_Lob.writeAppend(l_header, 1, l_sign);
    Dbms_Lob.writeAppend(l_header, 1, l_year);
    Dbms_Lob.writeAppend(l_header, 1, l_month);
    Dbms_Lob.writeAppend(l_header, 1, l_day);
    Dbms_Lob.writeAppend(l_header, 4, l_records);
    Dbms_Lob.writeAppend(l_header, 2, l_header_length);
    Dbms_Lob.writeAppend(l_header, 2, l_record_length);

    FOR i IN 1..16 LOOP
      Dbms_Lob.writeAppend(l_header, 1, NULL_BYTE);
    END LOOP;

    Dbms_Lob.writeAppend(l_header, 1, l_index_mdx);
    Dbms_Lob.writeAppend(l_header, 1, l_charset);
    Dbms_Lob.writeAppend(l_header, 1, NULL_BYTE);
    Dbms_Lob.writeAppend(l_header, 1, NULL_BYTE);

    RETURN l_header;
  END;

  -- ���� DBF
  FUNCTION WriteColumns
  RETURN BLOB
  IS
    l_columns BLOB;

    l_name RAW(11);
    l_type RAW(1);
    l_full_length RAW(1);
    l_decimal_length RAW(1);
    l_terminal RAW(1);
    l_loop_length RAW(4);

    l_iter BINARY_INTEGER;
  BEGIN
    Dbms_Lob.createtemporary(l_columns, TRUE);
    Dbms_Lob.OPEN(l_columns, Dbms_Lob.LOB_READWRITE);

    l_iter := 1;
    FOR i IN 1..cols.Count LOOP
      l_name := Utl_Raw.cast_to_raw(RPad(cols(i).name,11,Chr(0)));
      l_type := Utl_Raw.cast_to_raw(cols(i).type_);
      l_full_length := GetBytes(cols(i).full_length, 1);
      l_decimal_length := GetBytes(cols(i).decimal_length, 1);
      l_loop_length := GetBytes(l_iter, 4);

      Dbms_Lob.writeAppend(l_columns, 11, l_name);
      Dbms_Lob.writeAppend(l_columns, 1, l_type);
      Dbms_Lob.writeAppend(l_columns, 4, l_loop_length);
      Dbms_Lob.writeAppend(l_columns, 1, l_full_length);
      Dbms_Lob.writeAppend(l_columns, 1, l_decimal_length);

      FOR j IN 1..14 LOOP
        Dbms_Lob.writeAppend(l_columns, 1, NULL_BYTE);
      END LOOP;

      l_iter := l_iter + cols(i).full_length;

    END LOOP;

    l_terminal := Utl_Raw.cast_to_raw(Chr(13));
    Dbms_Lob.writeAppend(l_columns, 1, l_terminal);

    RETURN l_columns;
  END;

  -- �������
  PROCEDURE Export
  IS
    F1 Utl_File.FILE_TYPE;

    l_header BLOB;
    l_columns BLOB;
    l_bytes NUMBER;
    l_blob_length NUMBER;
  BEGIN
    F1 := Utl_File.FOPEN(pkg_dir, pkg_file, 'wb');

    l_header := WriteHeader();
    l_columns := WriteColumns();

    Utl_File.put_raw(F1, l_header);
    Utl_File.put_raw(F1, l_columns);

    l_bytes := 1;
    WHILE l_bytes < Dbms_Lob.GetLength(pkg_data) LOOP
      l_blob_length := Least(32000, Dbms_Lob.GetLength(pkg_data) - (l_bytes-1));
      Utl_File.put_raw(F1, Dbms_Lob.SubStr(pkg_data, l_blob_length, l_bytes));
      l_bytes := l_bytes + l_blob_length;
      Dbms_Output.put_line(l_blob_length || ' ' || l_bytes);
    END LOOP;
    Utl_File.put_raw(F1, Utl_Raw.cast_to_raw(Chr(26)));

    Utl_File.FCLOSE(F1);

    Dbms_Lob.freetemporary(pkg_data);
    Dbms_Lob.freetemporary(l_columns);
    Dbms_Lob.freetemporary(l_header);

  EXCEPTION
    WHEN OTHERS THEN
      IF Utl_File.IS_OPEN(F1) THEN Utl_File.FCLOSE(F1); END IF;
      RAISE;
  END;

  FUNCTION CountRecords RETURN NUMBER
  IS
    F1 Utl_File.FILE_TYPE;
    l_dbfFile BFILE;
    amount INTEGER;
    l_cnt_raw RAW(4);
    l_records BINARY_INTEGER;

  BEGIN
    l_dbfFile := BFileName(pkg_dir, pkg_file);
    Dbms_Lob.OPEN(l_dbfFile, Dbms_Lob.LOB_READONLY);

    amount := 4;
    Dbms_Lob.READ(l_dbfFile, amount, 5, l_cnt_raw);

    l_cnt_raw := Utl_Raw.REVERSE(l_cnt_raw);
    l_records := Utl_Raw.cast_to_binary_integer(l_cnt_raw);

    Dbms_Lob.CLOSE(l_dbfFile);

    RETURN l_records;

  EXCEPTION
    WHEN OTHERS THEN
      IF Dbms_Lob.FileIsOpen(l_dbfFile) = 1 THEN Dbms_Lob.CLOSE(l_dbfFile); END IF;
      RAISE;
  END;

END;
/

