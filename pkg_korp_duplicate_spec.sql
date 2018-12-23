CREATE OR REPLACE PACKAGE pkg_korp_duplicate_spec
--пакет используется в триггерах
-- t_korp_duplicate_spec_row, t_korp_duplicate_spec_oper
AS
  n_spec_code specifications.code%TYPE:=NULL;
  n_spec_spccode specifications.spccode%TYPE:=NULL;
END pkg_korp_duplicate_spec;
/