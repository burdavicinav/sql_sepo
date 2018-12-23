DECLARE
  l_priznak NUMBER;
  l_modify_user NUMBER;
BEGIN
  pkg_sepo_export_dce.Clear();
  pkg_sepo_export_dce.pkg_dce_type := -1;

  -- текущий пользователь
  -- вместо USER можно подставить логин любого пользователя
  SELECT
    code
  INTO
    l_modify_user
  FROM
    user_list
  WHERE
      loginName = USER;

  -- запрос отбирает все извещения на статусе "Производство",
  -- "Подготовка производства"
  FOR i IN (
    SELECT
      bo_ii.name,
      ii.todo,
      bo_dce.code,
      bo_dce.revision
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
              lv.name IN ( 'Производство', 'Подготовка производства' )
        )
      AND
        bo_dce.code = ii.itemCode
      AND
        bo_dce.TYPE IN (1, 2, 5, 22)

    UNION ALL

    SELECT
      bo_ii.name,
      ii.todo,
      bo_rel.code,
      bo_rel.revision
    FROM
      ii_items ii,
      business_objects bo_ii,
      business_objects bo,
      grspc_rel gr,
      konstrobj ko_rel,
      business_objects bo_rel,
      businessObj_states st,
      businessObj_promotion_levels lvl
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
              lv.name IN ( 'Производство', 'Подготовка производства' )
        )
      AND
        bo.code = ii.itemCode
      AND
        bo.TYPE IN (7,23)
      AND
        ii.todo IN (0,1)
      AND
        gr.grCode = bo.docCode
      AND
        ko_rel.unvCode = gr.code
      AND
        bo_rel.docCode = ko_rel.unvCode
      AND
        bo_rel.prodCode = ko_rel.prodCode
      AND
        st.code = bo_rel.today_state
      AND
        lvl.code = st.promLevel

    ) LOOP
      IF i.todo IN (0,1) THEN
        IF i.revision = 0 THEN l_priznak := 0;
        ELSE
          l_priznak := 1;

        END IF;
      ELSE
        l_priznak := i.todo;

      END IF;

      -- выборка данных для экспорта
      pkg_sepo_export_dce.SelectRow(
        i.code,
        SYSDATE,
        l_modify_user,
        0,
        l_priznak
        );

    END LOOP;

    -- экспорт выбранных данных
    pkg_sepo_export_dce.Export();

END;
/