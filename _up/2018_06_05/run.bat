chcp 1251
(
echo @db_up.sql
echo @pkg_sepo_raw_operations.sql
echo @pkg_sepo_system_objects.sql
echo @pkg_sepo_attr_operations.sql
echo @pkg_sepo_import_global.sql
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause