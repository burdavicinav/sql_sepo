BEGIN
  IF pkg_sepo_export_settings.isUpdateDCEAttrIZD THEN
    pkg_sepo_konstrobj.UpdateImportIZD(1);
    pkg_sepo_konstrobj.UpdateImportIZD(2);
    pkg_sepo_konstrobj.UpdateImportIZD(22);

    COMMIT;
  END IF;

END;
/