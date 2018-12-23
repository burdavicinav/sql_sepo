ALTER TABLE omp_sepo_properties move TABLESPACE omp_db;
ALTER TABLE sepo_eqp_model_folders move TABLESPACE omp_db;
ALTER TABLE sepo_eqp_model_records move TABLESPACE omp_db;
ALTER TABLE sepo_fail2 move TABLESPACE omp_db;
ALTER TABLE sepo_import_logs move TABLESPACE omp_db;
ALTER TABLE sepo_import_triggers_disable move TABLESPACE omp_db;
ALTER TABLE sepo_import_types move TABLESPACE omp_db;
ALTER TABLE sepo_oper_folder_codes move TABLESPACE omp_db;
ALTER TABLE sepo_oper_folders move TABLESPACE omp_db;
ALTER TABLE sepo_oper_recs move TABLESPACE omp_db;
ALTER TABLE sepo_osn_all move TABLESPACE omp_db;
ALTER TABLE sepo_osn_det move TABLESPACE omp_db;
ALTER TABLE sepo_osn_docs move TABLESPACE omp_db;
ALTER TABLE sepo_osn_docs_link_omp move TABLESPACE omp_db;
ALTER TABLE sepo_osn_se move TABLESPACE omp_db;
ALTER TABLE sepo_osn_sostav move TABLESPACE omp_db;
ALTER TABLE sepo_osn_sp move TABLESPACE omp_db;
ALTER TABLE sepo_osn_types move TABLESPACE omp_db;
ALTER TABLE sepo_professions move TABLESPACE omp_db;
ALTER TABLE sepo_professions_on_opers move TABLESPACE omp_db;
ALTER TABLE sepo_spc_materials_update move TABLESPACE omp_db;
ALTER TABLE sepo_spec_load_command move TABLESPACE omp_db;
ALTER TABLE sepo_spec_load_command_fields move TABLESPACE omp_db;
ALTER TABLE sepo_task_folder_list move TABLESPACE omp_db;
ALTER TABLE sepo_task_list move TABLESPACE omp_db;
ALTER TABLE sepo_tech_step_texts move TABLESPACE omp_db;
ALTER TABLE sepo_tech_steps move TABLESPACE omp_db;
ALTER TABLE sepo_xml_log move TABLESPACE omp_db;

SELECT * FROM dba_indexes
WHERE
    owner = 'OMP_ADM'
  AND
    tablespace_name != 'OMP_IND';

DECLARE

BEGIN
  FOR i IN (
    SELECT * FROM dba_indexes
    WHERE
        owner = 'OMP_ADM'
      AND
        table_name LIKE '%SEPO%'
      AND
        tablespace_name != 'OMP_IND'
      AND
        index_type = 'NORMAL'
  ) LOOP
--    Dbms_Output.put_line(i.index_name);
    EXECUTE IMMEDIATE 'ALTER INDEX ' || i.index_name || ' REBUILD' ||
      ' TABLESPACE OMP_IND';

  END LOOP;

END;
/

ALTER USER omp_adm DEFAULT TABLESPACE omp_db;