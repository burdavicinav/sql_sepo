CREATE OR REPLACE TRIGGER t_korp_duplicate_spec_row
                            AFTER INSERT OR UPDATE
                            ON specifications
                            FOR EACH ROW
/*Строчный триггер для проверки дубляжа сборочных
  материалов в спецификациях */
BEGIN
  --сохраняем значение добавляемой строки спецификации
   pkg_korp_duplicate_spec.n_spec_code:=:NEW.code;
   pkg_korp_duplicate_spec.n_spec_spccode:=:NEW.spccode;
END;
/