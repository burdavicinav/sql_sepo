SET NLS_LANG=AMERICAN_AMERICA.CL8MSWIN1251

chcp 1251
(
echo @up.sql
echo @pkg_sepo_techprocesses.pls
echo @pkg_sepo_import_global.pls
echo commit;
echo exit 
) | sqlplus omp_adm/eastsoft@omega

pause