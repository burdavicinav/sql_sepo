CREATE OR REPLACE PACKAGE pkg_sepo_export_settings
IS
  isResetDCESequence BOOLEAN := FALSE;
  isUpdateDCEAttrIZD BOOLEAN := TRUE;

END;
/