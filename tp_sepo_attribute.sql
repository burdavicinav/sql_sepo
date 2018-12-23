CREATE OR REPLACE TYPE tp_sepo_attribute AS object (
  l_code NUMBER,
  l_shortname VARCHAR2(100),
  l_name VARCHAR2(100),
  l_type NUMBER,
  l_value AnyData,
  l_meas_exists NUMBER,
  l_meas_value VARCHAR2(100),
  l_calc_type NUMBER,
  l_calc_value NUMBER,
  l_obj_type NUMBER,

  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value NUMBER := NULL) RETURN self AS result,
  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value VARCHAR2 := NULL) RETURN self AS result,
  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value DATE := NULL) RETURN self AS result,
  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value NUMBER := NULL) RETURN self AS result,
  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value VARCHAR2 := NULL) RETURN self AS result,
  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value DATE := NULL) RETURN self AS result,

  member PROCEDURE setObjType(p_obj_type NUMBER),
  member FUNCTION getObjType RETURN NUMBER,
  member FUNCTION getCode RETURN NUMBER,
  member PROCEDURE setCode(p_code NUMBER),
  member FUNCTION getValue RETURN AnyData,
  member PROCEDURE setValue(p_value AnyData),
  member PROCEDURE setValue(p_value NUMBER),
  member PROCEDURE setValue(p_value VARCHAR2),
  member PROCEDURE setValue(p_value DATE)
);
/

CREATE OR REPLACE TYPE BODY tp_sepo_attribute
AS
  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value NUMBER)
  RETURN self AS result
  IS
  BEGIN
    setCode(p_code);
    setValue(p_value);
  END;

  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value VARCHAR2 := NULL) RETURN self AS result
  IS
  BEGIN
    setCode(p_code);
    setValue(p_value);
  END;

  constructor FUNCTION tp_sepo_attribute(p_code NUMBER, p_value DATE := NULL) RETURN self AS result
  IS
  BEGIN
    setCode(p_code);
    setValue(p_value);
  END;

  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value NUMBER)
  RETURN self AS result
  IS
  BEGIN
    l_shortname := p_shortname;
    setObjType(p_obj_type);
    setValue(p_value);

    RETURN;
  END;

  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value VARCHAR2)
  RETURN self AS result
  IS
  BEGIN
    l_shortname := p_shortname;
    setObjType(p_obj_type);
    setValue(p_value);

    RETURN;
  END;

  constructor FUNCTION tp_sepo_attribute(p_obj_type NUMBER, p_shortname VARCHAR2, p_value DATE)
  RETURN self AS result
  IS
  BEGIN
    l_shortname := p_shortname;
    setObjType(p_obj_type);
    setValue(p_value);

    RETURN;
  END;

  member PROCEDURE setCode(p_code NUMBER)
  IS
  BEGIN
    SELECT
      objtype,
      code,
      shortname,
      name,
      value_type,
      varmeas,
      meascode,
      is_calculated
    INTO
      l_obj_type,
      l_code,
      l_shortname,
      l_name,
      l_type,
      l_meas_exists,
      l_meas_value,
      l_calc_type
    FROM
      obj_attributes data
    WHERE
        code = p_code;

  EXCEPTION
    WHEN No_Data_Found THEN
      RAISE pkg_sepo_attr_operations.NO_ATTR_FOUND;
    WHEN OTHERS THEN
      RAISE;
  END;

  member PROCEDURE setObjType(p_obj_type NUMBER)
  IS
  BEGIN
    SELECT
      code,
      shortname,
      name,
      value_type,
      varmeas,
      meascode,
      is_calculated
    INTO
      l_code,
      l_shortname,
      l_name,
      l_type,
      l_meas_exists,
      l_meas_value,
      l_calc_type
    FROM
      obj_attributes data
    WHERE
        data.objType = p_obj_type
      AND
        data.shortName = l_shortname;

    l_obj_type := p_obj_type;

  EXCEPTION
    WHEN No_Data_Found THEN
      RAISE pkg_sepo_attr_operations.NO_ATTR_FOUND;
    WHEN OTHERS THEN
      RAISE;

  END;

  member FUNCTION getObjType RETURN NUMBER
  IS
  BEGIN
    RETURN l_obj_type;
  END;

  member FUNCTION getCode RETURN NUMBER
  IS
  BEGIN
    RETURN l_code;
  END;

  member FUNCTION getValue RETURN AnyData
  IS
  BEGIN
    RETURN l_value;
  END;

  member PROCEDURE setValue(p_value AnyData)
  IS
  BEGIN
    l_value := p_value;
  END;

  member PROCEDURE setValue(p_value NUMBER)
  IS
  BEGIN
    IF l_type NOT IN (2,3) THEN
      RAISE pkg_sepo_attr_operations.ATTR_VALUE_EXCEPTION;
    END IF;

    l_value := AnyData.ConvertNumber(p_value);
  END;

  member PROCEDURE setValue(p_value VARCHAR2)
  IS
  BEGIN
    IF l_type NOT IN (1) THEN
      RAISE pkg_sepo_attr_operations.ATTR_VALUE_EXCEPTION;
    END IF;

    l_value := AnyData.ConvertVarchar2(p_value);
  END;

  member PROCEDURE setValue(p_value DATE)
  IS
  BEGIN
    IF l_type NOT IN (4) THEN
      RAISE pkg_sepo_attr_operations.ATTR_VALUE_EXCEPTION;
    END IF;

    l_value := AnyData.ConvertVarchar2(p_value);
  END;

END;
/

DECLARE
  l_attr tp_sepo_attribute;
BEGIN
  l_attr := tp_sepo_attribute(2, 'DCE', 2);
  Dbms_Output.put_line(l_attr.getCode());
EXCEPTION
  WHEN pkg_sepo_attr_operations.NO_ATTR_FOUND THEN
    Raise_Application_Error(-20101, 'Атрибут не найден');
  WHEN pkg_sepo_attr_operations.ATTR_VALUE_EXCEPTION THEN
    Raise_Application_Error(-20102, 'Значение атрибута не соответствует его типу!');

END;
/