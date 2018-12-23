chcp 1251
(
echo @db_up.sql
echo @PKG_SEPO_IMPORT_GLOBAL.pls
echo @version.sql
echo commit
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause