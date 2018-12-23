chcp 1251
(
echo @db_up.sql
echo @pkg_sepo_raw_operations.pls
echo @pkg_sepo_techprocesses.sql
echo @pkg_sepo_import_global.pls
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause