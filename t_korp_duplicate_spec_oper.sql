CREATE OR  REPLACE TRIGGER t_korp_duplicate_spec_oper
                           AFTER INSERT OR UPDATE
                           ON specifications
/*����������� ������� ��� �������� ������� ���������
  ���������� � ������������� */
DECLARE
  n_count NUMBER;
  --��������� ���������
  n_ko_type konstrobj.itemtype%TYPE:=5;
BEGIN
    SELECT Count(*)
     INTO   n_count
      FROM
        specifications
       WHERE
         code=pkg_korp_duplicate_spec.n_spec_code
        AND
         spccode= pkg_korp_duplicate_spec.n_spec_spccode
        AND
         SECTION=n_ko_type;
    --���� ��. �������� ����������� �� ������� ������
    IF n_count>1 THEN
        pkg_korp_duplicate_spec.n_spec_code:=NULL;
        pkg_korp_duplicate_spec.n_spec_spccode:=NULL;
        Raise_Application_Error(-20133,'������ ������� ��� ���������� � ������������.');
    END IF;

    pkg_korp_duplicate_spec.n_spec_code:=NULL;
    pkg_korp_duplicate_spec.n_spec_spccode:=NULL;


END;
/