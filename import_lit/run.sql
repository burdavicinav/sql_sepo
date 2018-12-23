ALTER TRIGGER taiur_sepo_export_materials DISABLE;
ALTER TRIGGER tau_sepo_export_materials DISABLE;

EXEC pkg_sepo_import_maters.LoadMixture();
COMMIT;

ALTER TRIGGER taiur_sepo_export_materials ENABLE;
ALTER TRIGGER tau_sepo_export_materials ENABLE;