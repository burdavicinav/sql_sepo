CREATE USER tflex_user IDENTIFIED BY "tflex_user"
DEFAULT TABLESPACE omp_db
TEMPORARY TABLESPACE temp;

GRANT CREATE SESSION TO tflex_user;
GRANT SELECT ON user_list TO tflex_user;
GRANT SELECT ON owner_name TO tflex_user;
GRANT SELECT ON businessobj_types TO tflex_user;
GRANT SELECT ON businessobj_states TO tflex_user;
GRANT EXECUTE ON pkg_sepo_tflex_synch_omp TO tflex_user;