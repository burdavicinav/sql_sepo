-- представление для атрибутов оснастки
-- выполнять в случае перестройки атрибутов
DECLARE
  l_table_31 NUMBER;
  l_tblkey_31 NUMBER;
  l_reckey_31 NUMBER;
  l_art_31 NUMBER;
  l_vo_31 NUMBER;
  l_table_32 NUMBER;
  l_tblkey_32 NUMBER;
  l_reckey_32 NUMBER;
  l_art_32 NUMBER;
  l_vo_32 NUMBER;
  l_table_33 NUMBER;
  l_tblkey_33 NUMBER;
  l_reckey_33 NUMBER;
  l_vo_33 NUMBER;
BEGIN
  l_table_31 := pkg_sepo_attr_operations.getcode(31, 'Table');
  l_tblkey_31 := pkg_sepo_attr_operations.getcode(31, 'TBLKey');
  l_reckey_31 := pkg_sepo_attr_operations.getcode(31, 'RecKey');
  l_vo_31 := pkg_sepo_attr_operations.getcode(31, 'О_ВО');
  l_art_31 := pkg_sepo_attr_operations.getcode(31, 'ART_ID');

  l_table_32 := pkg_sepo_attr_operations.getcode(32, 'Table');
  l_tblkey_32 := pkg_sepo_attr_operations.getcode(32, 'TBLKey');
  l_reckey_32 := pkg_sepo_attr_operations.getcode(32, 'RecKey');
  l_vo_32 := pkg_sepo_attr_operations.getcode(32, 'О_ВО');
  l_art_32 := pkg_sepo_attr_operations.getcode(32, 'ART_ID');

  l_table_33 := pkg_sepo_attr_operations.getcode(33, 'Table');
  l_tblkey_33 := pkg_sepo_attr_operations.getcode(33, 'TBLKey');
  l_reckey_33 := pkg_sepo_attr_operations.getcode(33, 'RecKey');
  l_vo_33 := pkg_sepo_attr_operations.getcode(33, 'О_ВО');

  EXECUTE IMMEDIATE
    'create or replace view v_sepo_fixture_attrs as ' ||
    'select socode, objtype, table_, tblkey, reckey, o_vo, art_id ' ||
    'from (select ' ||
      'socode,' ||
      'a_' || l_table_31 || ' as table_,' ||
      'a_' || l_tblkey_31 || ' as tblkey,' ||
      'a_' || l_reckey_31 || ' as reckey,' ||
      'a_' || l_vo_31 || ' AS o_vo,' ||
      'a_' || l_art_31 || ' as art_id ' ||
    'from ' ||
      'obj_attr_values_31 ' ||
    'union all ' ||
    'select ' ||
      'socode,' ||
      'a_' || l_table_32 || ' as table_,' ||
      'a_' || l_tblkey_32 || ' as tblkey,' ||
      'a_' || l_reckey_32 || ' as reckey,' ||
      'a_' || l_vo_32 || ' AS o_vo,' ||
      'a_' || l_art_32 || ' as art_id ' ||
    'from ' ||
      'obj_attr_values_32 ' ||
    'union all ' ||
    'select ' ||
      't1.socode,' ||
      'a_' || l_table_33 || ' as table_,' ||
      'a_' || l_tblkey_33 || ' as tblkey,' ||
      'a_' || l_reckey_33 || ' as reckey,' ||
      'a_' || l_vo_33 || ' AS o_vo,' ||
      'null as art_id ' ||
    'from ' ||
      'obj_attr_values_33 t1,'||
      'obj_attr_values_33_2 t2 ' ||
    'where t1.socode = t2.socode),' ||
    'omp_objects ' ||
    'where code = socode';

END;
/