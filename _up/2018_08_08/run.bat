chcp 1251
(
echo @db_up.sql
echo @pkg_sepo_import_maters.sql
echo @PKG_SEPO_TECHPROCESSES.pls
echo @PKG_SEPO_IMPORT_GLOBAL.pls
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause