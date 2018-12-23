BEGIN
  pkg_sepo_import_maters.Init(
    'OMP_ADM',
    'нюясо',
    pkg_sepo_import_maters.MAT_STATE_CONFIRMED
    );

  pkg_sepo_import_maters.CreateMatClassify('FoxPro');
  pkg_sepo_import_maters.CreateTMCClassify('FoxPro');

  pkg_sepo_import_maters.Clear();
END;
/