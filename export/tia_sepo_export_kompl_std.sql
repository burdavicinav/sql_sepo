PROMPT CREATE OR REPLACE TRIGGER tia_sepo_export_kompl_std
CREATE OR REPLACE TRIGGER tia_sepo_export_kompl_std
AFTER INSERT ON businessobj_promotion
FOR EACH ROW
DECLARE
  l_boType NUMBER;
  l_revision NUMBER;
  l_prev_lvl businessObj_states.name%TYPE;
  l_current_lvl businessObj_states.name%TYPE;
  l_current_sublvl businessObj_states.name%TYPE;
  l_modify_user NUMBER;
  l_lvl_50 VARCHAR2(30);
  l_sublvl_50 VARCHAR2(30);

  l_status NUMBER;
  l_priznak NUMBER;
BEGIN
  --
  -- триггер запускает экспорт на стандартные изделия, прочие изделия и ИИ
  --

  l_lvl_50 := 'Подготовка производства';
  l_sublvl_50 := 'Подуровень 1';

  -- получение типа и номера ревизии бизнес-объекта
  SELECT
    TYPE,
    revision
  INTO
    l_boType,
    l_revision
  FROM
    business_objects
  WHERE
      code = :new.businessObj;

  -- триггер срабатывает только на стандартные изделия, прочие изделия и ИИ
  IF l_boType NOT IN (3, 4, 50) THEN RETURN; END IF;

  -- если операция не задана, то ничего не делать
  IF :new.operation IS NULL THEN RETURN; END IF;

  -- получение текущего и следующего статусов операции
  SELECT
    lv_cur.name,
    lv_next.name,
    sb_next.name
  INTO
    l_prev_lvl,
    l_current_lvl,
    l_current_sublvl
  FROM
    businessobj_operations opers,
    businessobj_states cur,
    businessobj_promotion_levels lv_cur,
    businessobj_states next_,
    businessobj_promotion_levels lv_next,
    businessobj_sublevels sb_next
  WHERE
      opers.code = :new.operation
    AND
      opers.current_state = cur.code(+)
    AND
      cur.promLevel = lv_cur.code(+)
    AND
      opers.next_state = next_.code
    AND
      next_.promLevel = lv_next.code
    AND
      next_.sublevel = sb_next.code(+);

  -- экспорт прочих изделий (Проектирование -> Производство)
  IF l_boType = 4 AND
       l_prev_lvl = 'Проектирование' AND l_current_lvl = 'Производство' THEN

    l_status := 0;
    l_priznak := NULL;

    SELECT
      code
    INTO
      l_modify_user
    FROM
      user_list
    WHERE
        loginName = USER;

    pkg_sepo_export_kompl.Clear();

    IF l_revision = 0 THEN l_priznak := 0; ELSE l_priznak := 1; END IF;
    pkg_sepo_export_kompl.SelectRow(
      :new.businessObj,
      SYSDATE,
      l_modify_user,
      l_status,
      l_priznak
      );

    pkg_sepo_export_kompl.Export();

  -- экспорт стандартных изделий (Проектирование -> Производство)
  ELSIF l_boType = 3 AND
          l_prev_lvl = 'Проектирование' AND l_current_lvl = 'Производство' THEN
    l_status := 0;
    l_priznak := NULL;

    SELECT
      code
    INTO
      l_modify_user
    FROM
      user_list
    WHERE
        loginName = USER;

    pkg_sepo_export_dce.Clear();
    pkg_sepo_export_dce.pkg_dce_type := 3;

    IF l_revision = 0 THEN l_priznak := 0; ELSE l_priznak := 1; END IF;
    pkg_sepo_export_dce.SelectRow(
      :new.businessObj,
      SYSDATE,
      l_modify_user,
      l_status,
      l_priznak
      );

    pkg_sepo_export_dce.Export();

  -- экспорт содержимого извещения на изменение
  -- (Любой -> Подготовка производства/Архив КД)
  ELSIF
    l_boType = 50 AND
    l_current_lvl = l_lvl_50 AND
    l_current_sublvl = l_sublvl_50 THEN

    l_status := 0;

    pkg_sepo_export_dce.Clear();
    pkg_sepo_export_dce.pkg_dce_type := -1;

    -- экспортируются сборочные узлы, детали, сборочные материалы, комплекты
    -- а также исполнения групповых спецификаций и комплектов в случаях,
    -- когда операция извещения - "Выпустить" или "Изменить"

    FOR i IN (
      SELECT
        data.todo,
        data.code,
        data.prodcode,
        data.name,
        data.botype,
        data.revision,
        rev.revcount,
        coalesce(cnt.value_, 0) AS cnt
      FROM
        (
        SELECT
          ii.todo,
          bo.code,
          bo.prodcode,
          bo.name,
          bo.TYPE AS botype,
          bo.revision
        FROM
          ii_items ii,
          business_objects bo,
          businessobj_states st,
          businessobj_promotion_levels lvl,
          businessobj_sublevels sub
        WHERE
            ii.iiCode = :new.businessObj
          AND
            bo.code = ii.itemCode
          AND
            bo.TYPE IN (1, 2, 5, 22)
          AND
            st.code = bo.today_state
          AND
            lvl.code = st.promlevel
          AND
            sub.code (+)= st.sublevel
          AND
            (
              lvl.name != l_lvl_50
            AND
              coalesce(sub.name, '0') != l_sublvl_50
            )

        UNION ALL

        SELECT
          ii.todo,
          bo_rel.code,
          bo_rel.prodcode,
          bo_rel.name,
          bo_rel.TYPE,
          bo_rel.revision
        FROM
          ii_items ii,
          business_objects bo,
          grspc_rel gr,
          konstrobj ko_rel,
          business_objects bo_rel,
          businessobj_states st,
          businessobj_promotion_levels lvl,
          businessobj_sublevels sub
        WHERE
            ii.iiCode = :new.businessObj
          AND
            bo.code = ii.itemCode
          AND
            bo.TYPE IN (7,23)
          AND
            ii.todo IN (0,1)
          AND
            gr.grCode = bo.docCode
          AND
            gr.deleteDate IS NULL
          AND
            ko_rel.unvCode = gr.code
          AND
            bo_rel.docCode = ko_rel.unvCode
          AND
            bo_rel.prodCode = ko_rel.prodCode
          AND
            ko_rel.itemtype IN (1,22)
          AND
            st.code = bo.today_state
          AND
            lvl.code = st.promlevel
          AND
            sub.code (+)= st.sublevel
          AND
            (
              lvl.name != l_lvl_50
            AND
              coalesce(sub.name, '0') != l_sublvl_50
            )
        ) data
        JOIN
        (
          SELECT
            st.botype,
            st.revcount
          FROM
            businessobj_states st,
            businessobj_promotion_levels lvl,
            businessobj_sublevels sub
          WHERE
              lvl.code = st.promlevel
            AND
              sub.code = st.sublevel
            AND
              st.botype IN (1, 2, 5, 22)
            AND
              lvl.name = l_lvl_50
            AND
              sub.name = l_sublvl_50
        ) rev
        ON
            data.botype = rev.botype
        left JOIN
        (
          SELECT
            bo.prodcode,
            Count(*) AS value_
          FROM
            business_objects bo,
            businessobj_states bs,
            businessobj_promotion_levels lvl,
            businessobj_sublevels sub
          WHERE
              bs.code = bo.today_state
            AND
              lvl.code = bs.promlevel
            AND
              sub.code = bs.sublevel
            AND
              lvl.name = l_lvl_50
            AND
              sub.name = l_sublvl_50
          GROUP BY
            bo.prodcode
        ) cnt
        ON
            data.prodcode = cnt.prodcode

    ) LOOP
      IF i.revcount != -1 AND i.cnt >= i.revcount THEN
        Raise_Application_Error(
          -20600,
          'Ошибка! Превышено максимальное количество ревизий на уровне продвижения '
          || l_lvl_50 || ': ' || i.name || ' [' || i.revision || '].'
          );
      END IF;

      IF i.todo IN (0,1) THEN
        IF i.revision = 0 THEN l_priznak := 0;
        ELSE
          l_priznak := 1;

        END IF;
      ELSE
        l_priznak := i.todo;

      END IF;

      SELECT
        code
      INTO
        l_modify_user
      FROM
        user_list
      WHERE
          loginName = USER;

      pkg_sepo_export_dce.SelectRow(
        i.code,
        SYSDATE,
        l_modify_user,
        l_status,
        l_priznak
        );

    END LOOP;

    pkg_sepo_export_dce.Export();


  END IF;

END;
/

