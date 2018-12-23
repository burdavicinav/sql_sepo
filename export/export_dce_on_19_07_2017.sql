DECLARE
  l_priznak NUMBER;
  l_modify_user NUMBER;
  l_modify_date DATE;
BEGIN
  pkg_sepo_export_dce.Clear();
  pkg_sepo_export_dce.pkg_dce_type := -1;

  -- ������� ������������
  -- ������ USER ����� ���������� ����� ������ ������������
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- ������� ���� ������������� �� 19.07.2017
  l_modify_date := To_Date('19.07.2017', 'DD.MM.YYYY');

  -- ������ �������� ��� ��������� �� ������� "������������"
  -- �� 19.07.2017
  FOR i IN (
    SELECT
      bo_ii.name,
      ii.todo,
      bo_dce.code
    FROM
      ii_items ii,
      business_objects bo_ii,
      business_objects bo_dce
    WHERE
        bo_ii.code = ii.iiCode
      AND
        bo_ii.TYPE = 50
      AND
        EXISTS
        (
          SELECT
            1
          FROM
            businessObj_promotion bop,
            businessObj_states st,
            businessObj_promotion_levels lv
          WHERE
              bop.businessObj = bo_ii.code
            AND
              st.code = bop.current_state
            AND
              lv.code = st.promLevel
            AND
              lv.name = '������������'
            AND
              To_Date(To_Char(bop.stateDate, 'DD.MM.YYYY'), 'DD.MM.YYYY') =
                l_modify_date
        )
      AND
        bo_dce.code = ii.itemCode
      AND
        bo_dce.TYPE IN (1, 2, 5, 22)
    ) LOOP
      l_priznak := i.todo;

      -- ������� ������ ��� ��������
      pkg_sepo_export_dce.SelectRow(
        i.code,
        l_modify_date,
        l_modify_user,
        0,
        l_priznak
        );

    END LOOP;

    -- ������� ��������� ������
    pkg_sepo_export_dce.Export();

END;
/