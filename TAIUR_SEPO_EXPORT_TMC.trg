PROMPT CREATE OR REPLACE TRIGGER taiur_sepo_export_tmc
CREATE OR REPLACE TRIGGER taiur_sepo_export_tmc
AFTER INSERT OR UPDATE ON stock_other
FOR EACH ROW
DECLARE
  l_create_user NUMBER;
  l_modify_user NUMBER;
BEGIN
  -- ���������� �� �������������� �����������
  IF UPDATING THEN
    IF Nvl(:old.Sign, 0) != Nvl(:new.Sign, 0) THEN
      Raise_Application_Error(
        -20101,
        '�������������� ����������� ���������! ���������� � ��������������.'
      );
    END IF;

  END IF;

  -- �������� ������� ��������� ������ �� ���������� ���������
  -- ����������� ������������, �������������� ������
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- ����������� ������������, ���������� ������
  l_create_user := :new.recUser;

  -- ���������� ������
  INSERT INTO sepo_materials_temp
  VALUES
  (:new.code, :new.Sign, :new.measCode, NULL, NULL,
      :new.recDate, SYSDATE, l_create_user, l_modify_user,
        :old.is_annul, :new.is_annul);

END;

/

