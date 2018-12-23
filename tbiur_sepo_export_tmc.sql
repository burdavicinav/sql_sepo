CREATE OR REPLACE TRIGGER tbiur_sepo_export_tmc
BEFORE INSERT OR UPDATE ON stock_other
FOR EACH ROW
DECLARE
  TYPE t_attr_dict IS TABLE OF NUMBER INDEX BY obj_attributes.name%TYPE;
  l_attrs t_attr_dict;
BEGIN
  -- формирование наименования ТМЦ
  l_attrs.DELETE();

  FOR i IN (
    SELECT * FROM obj_attributes
    WHERE
        objtype = 1000045
  ) LOOP
    l_attrs(i.shortName) := i.code;

  END LOOP;

  EXECUTE IMMEDIATE
    'SELECT ' ||
      'A_' || l_attrs('NAIM') || ' || '' / '' || ' ||
      'A_' || l_attrs('MARK') || ' || '' / '' || ' ||
      'A_' || l_attrs('GOST') || ' || '' / '' || ' ||
      'A_' || l_attrs('SORM') || ' || '' / '' || ' ||
      'A_' || l_attrs('DM') || ' || '' / '' || ' ||
      'A_' || l_attrs('DL') || ' || '' / '' || ' ||
      'A_' || l_attrs('CHIR') || ' || '' / '' || ' ||
      'A_' || l_attrs('TOL') ||
    ' FROM' ||
      ' obj_attr_values_1000045' ||
    ' WHERE' ||
        ' soCode = :1'
    INTO
      :new.name
    USING
      :new.code;

END;
/