CREATE OR  REPLACE TRIGGER t_korp_duplicate_spec_oper
                           AFTER INSERT OR UPDATE
                           ON specifications
/*Операторный триггер для проверки дубляжа сборочных
  материалов в спецификациях */
DECLARE
  n_count NUMBER;
  --сборочные материалы
  n_ko_type konstrobj.itemtype%TYPE:=5;
BEGIN
    SELECT Count(*)
     INTO   n_count
      FROM
        specifications
       WHERE
         code=pkg_korp_duplicate_spec.n_spec_code
        AND
         spccode= pkg_korp_duplicate_spec.n_spec_spccode
        AND
         SECTION=n_ko_type;
    --если сб. материал дублируется то генерим ошибку
    IF n_count>1 THEN
        pkg_korp_duplicate_spec.n_spec_code:=NULL;
        pkg_korp_duplicate_spec.n_spec_spccode:=NULL;
        Raise_Application_Error(-20133,'Данный элемент уже существует в спецификации.');
    END IF;

    pkg_korp_duplicate_spec.n_spec_code:=NULL;
    pkg_korp_duplicate_spec.n_spec_spccode:=NULL;


END;
/