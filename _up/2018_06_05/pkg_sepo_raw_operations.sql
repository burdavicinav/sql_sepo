CREATE OR REPLACE PACKAGE pkg_sepo_raw_operations
IS
  -- ����� ��� ������ � ��������� �������
  -- ���������� ���� �� ������ exporttodbf

  -- ������� ����
  NULL_BYTE CONSTANT RAW(1) := Utl_Raw.cast_to_raw(Chr(0));
  -- ����� �����
  END_FILE CONSTANT RAW(1) := Utl_Raw.cast_to_raw(Chr(26));

  -- ������������ ���������
  CP866 CONSTANT NUMBER := 1;
  WIN1251 CONSTANT NUMBER := 2;

  FUNCTION GetBytes(
    p_raw RAW,
    p_count NUMBER
  )
  RETURN RAW;

  -- ����� � ����� (4 �����)
  FUNCTION GetBytes(
    p_number BINARY_INTEGER,
    p_count_bytes NUMBER DEFAULT 4
    )
  RETURN RAW;

  -- ������ � ����� � ������������ ��������������� ���������
  FUNCTION GetBytes(
    p_str VARCHAR2,
    p_isterminal BOOLEAN DEFAULT TRUE,
    p_is_convert BOOLEAN DEFAULT FALSE,
    p_cs_old NUMBER DEFAULT WIN1251,
    p_cs_new NUMBER DEFAULT CP866)
  RETURN RAW;

  -- ���� � �����
  FUNCTION GetBytes(
    p_date DATE
  )
  RETURN RAW;

  FUNCTION GetNullBytes(
    p_count NUMBER
  )
  RETURN RAW;

END;
/

CREATE OR REPLACE PACKAGE BODY pkg_sepo_raw_operations
IS
  FUNCTION GetBytes(
    p_raw RAW,
    p_count NUMBER
  )
  RETURN RAW
  IS
  BEGIN
    RETURN Utl_Raw.copies(p_raw, p_count);
  END;

  FUNCTION GetBytes(
    p_number BINARY_INTEGER,
    p_count_bytes NUMBER DEFAULT 4
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
    p_isterminal BOOLEAN DEFAULT TRUE,
    p_is_convert BOOLEAN DEFAULT FALSE,
    p_cs_old NUMBER DEFAULT WIN1251,
    p_cs_new NUMBER DEFAULT CP866)
  RETURN RAW
  IS
    l_raw RAW(255);
  BEGIN
    l_raw := Utl_Raw.cast_to_raw(p_str);
    IF p_isterminal THEN
      l_raw := Utl_Raw.Concat(l_raw, null_byte);

    END IF;

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

  FUNCTION GetNullBytes(
    p_count NUMBER
  )
  RETURN RAW
  IS
  BEGIN
    RETURN GetBytes(null_byte, p_count);
  END;

END;
/