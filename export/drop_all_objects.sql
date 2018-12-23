DROP TRIGGER tia_sepo_export_kompl_std;
DROP PACKAGE pkg_sepo_export_dce;
DROP TRIGGER tbi_sepo_konstrobj;
--DROP SEQUENCE sq_sepo_dce;
DROP TABLE sepo_export_dce;
DROP PACKAGE pkg_sepo_export_kompl;
DROP TABLE sepo_export_kompl;
DROP TRIGGER taiur_sepo_export_materials;
DROP TRIGGER tai_sepo_export_materials;
DROP TRIGGER tau_sepo_export_materials;
DROP TRIGGER taiur_sepo_export_tmc;
DROP TRIGGER taiu_sepo_export_tmc;
DROP PACKAGE pkg_sepo_export_materials;
DROP TABLE sepo_materials_temp;
DROP TABLE sepo_export_materials;
DROP PACKAGE pkg_sepo_materials;
DROP PACKAGE exportToDBF;
DROP PACKAGE pkg_sepo_konstrobj;

BEGIN
  IF pkg_sepo_export_settings.isResetDCESequence THEN
    EXECUTE IMMEDIATE 'DROP SEQUENCE sq_sepo_dce';
  END IF;

END;