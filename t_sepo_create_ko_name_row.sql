CREATE OR REPLACE TRIGGER t_sepo_create_ko_name_row
    BEFORE INSERT OR UPDATE
    ON konstrobj
    FOR EACH ROW
    WHEN (NEW.itemtype IN (4,3) AND NEW.name IS NULL)
/*
  Доработка СЭПО. Строчный триггер формирует(срабатывает только на прочих изделиях )
  наименование прочего изделия а основе заполненных атрибутов.

  UP 03.09.2017. Наименование заполняется только в случае, если его значение не задано.
*/
DECLARE
  l_name VARCHAR2(150);
  NPKI VARCHAR2(256);
  IND VARCHAR2(256);
  VID VARCHAR2(256);
  CHR VARCHAR2(256);
  NOMZ VARCHAR2(256);
  EDN VARCHAR2(256);
  DOP VARCHAR2(256);
  VISP VARCHAR2(256);
  GOST VARCHAR2(256);
  GOST1 VARCHAR2(256);
  VPR  VARCHAR2(256);
  NAIMD VARCHAR2(256);
  CHNDN VARCHAR2(256);
  OKON VARCHAR2(256);
 --получаем цифровую часть столбца из таблицы атрибутов
  FUNCTION get_attr_code (s_attr_name VARCHAR2,n_bocode konstrobj.bocode%TYPE)
   RETURN VARCHAR2
  AS
    s_value VARCHAR2(300);
    n_code obj_attributes.code%TYPE;
  BEGIN
      SELECT  code INTO n_code FROM obj_attributes WHERE shortname=s_attr_name AND objtype=:NEW.itemtype;

      EXECUTE IMMEDIATE 'SELECT a_'||To_Char(n_code)||' FROM obj_attr_values_'||To_Char(:NEW.itemtype)||' where socode=:bocode'
      INTO s_value USING n_bocode;

      RETURN s_value;
  END;
BEGIN
    CASE
    --если прочее
    WHEN :NEW.itemtype=4 THEN
        NPKI:=get_attr_code ('NPKI',:NEW.bocode);
        IND:=get_attr_code ('IND',:NEW.bocode);
        VID:=get_attr_code ('VID',:NEW.bocode);
        CHR:=get_attr_code ('CHR',:NEW.bocode);
        NOMZ:=get_attr_code ('NOMZ',:NEW.bocode);
        EDN:=get_attr_code ('EDN',:NEW.bocode);
        DOP:=get_attr_code ('DOP',:NEW.bocode);
        VISP:=get_attr_code ('VISP',:NEW.bocode);
        GOST:=get_attr_code ('GOST',:NEW.bocode);
        GOST1:=get_attr_code ('GOST1',:NEW.bocode);
        VPR:=get_attr_code ('VPR',:NEW.bocode);

        :new.name := case when NPKI is null THEN NULL ELSE NPKI end
                  ||case when IND is null THEN NULL ELSE ' '||IND END
                  ||case when VID is null THEN NULL ELSE ' '||VID end
                  ||case when Chr is null THEN NULL ELSE ' - '||Chr end
                  ||case when NOMZ is null THEN NULL ELSE ' - '||NOMZ END
                  ||case when EDN is null THEN NULL ELSE ' '||EDN end
                  ||case when DOP is null THEN NULL ELSE ' +/- ' ||DOP end
                  ||case when VISP is null THEN NULL ELSE '% - '||VISP END
                  ||case when VPR is null THEN NULL ELSE ' '||VPR end
                  ||case when GOST is null THEN NULL ELSE ' '||GOST end
                  ||case when GOST1 is null THEN NULL ELSE ' '||GOST1 END;

      --если стандартное
      WHEN :NEW.itemtype=3 THEN
        NAIMD:=get_attr_code ('NAIMD',:NEW.bocode);
        CHNDN:=get_attr_code ('CHNDN',:NEW.bocode);
        OKON:=get_attr_code ('OKON',:NEW.bocode);
        :new.name :=case WHEN NAIMD is null THEN NULL ELSE NAIMD END
                  ||case WHEN CHNDN is null then NULL ELSE ' '||CHNDN END
                  ||case WHEN OKON is null THEN NULL ELSE ' '||OKON END;

    END CASE;

END;