-- ������ ���������� �� ����������
DROP TRIGGER tr_sepo_export_materials;
DROP TRIGGER tr_sepo_export_new_tmc;
DROP TRIGGER tr_sepo_export_update_tmc;
DROP TABLE sepo_export_materials;
DROP PACKAGE pkg_sepo_export_materials;
DROP PACKAGE exportToDBF;

-- ������ ���������� �� ���
DROP TRIGGER tia_sepo_export_kompl;
DROP PACKAGE pkg_sepo_export_kompl;
DROP TABLE sepo_export_kompl;