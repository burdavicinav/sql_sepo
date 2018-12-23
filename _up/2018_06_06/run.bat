chcp 1251
(
echo @pkg_sepo_import_global.sql
echo @db_up.sql
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause