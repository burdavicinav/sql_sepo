chcp 1251
(
echo @db_up.sql
echo @pkg_sepo_import_global.sql
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause