chcp 1251
(
echo @18_01_24_up.sql
echo @18_02_07_up.sql
echo @pkg_sepo_attr_operations.pls
echo @pkg_sepo_import_global.pls
echo @up.sql
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause