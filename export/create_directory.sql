DROP DIRECTORY DBF_DIR;

CREATE DIRECTORY DBF_DIR AS 'C:\Servers\Oracle\app\oracle\oradata\omega\dbf';
GRANT WRITE ON DIRECTORY DBF_DIR TO omp_adm;