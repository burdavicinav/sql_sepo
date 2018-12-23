CREATE OR REPLACE TRIGGER tbi_sepo_opers_approval_history
BEFORE INSERT ON bo_opers_approval_history
FOR EACH ROW
WHEN (NEW.signed = 1)
DECLARE
  l_boType NUMBER;
  l_current_state businessobj_promotion_levels.name%TYPE;
  l_next_state businessobj_promotion_levels.name%TYPE;
  l_msg_warning NUMBER;

  l_not_found_attribute EXCEPTION;
BEGIN
  -- при подписании листа согласования перевода с уровня продвижения
  -- "Проектирование" на уровень "Проектирование" производится проверка
  -- существования двух и более ревизий на увронях продвижений
  -- "Проектирование" и "Подготовка производства". Если проверка успешна,
  -- то номера ревизий записываются в атрибут элемента извещения
  -- "MSG_WARNING".

  -- получение операции текущего листа согласования
  SELECT
    op.botype,
    c_lvl.name,
    n_lvl.name
  INTO
    l_botype,
    l_current_state,
    l_next_state
  FROM
    bo_opers_approval boa,
    bo_opers_approval_schemes bos,
    businessobj_operations op,
    businessobj_states cs,
    businessobj_states ns,
    businessobj_promotion_levels c_lvl,
    businessobj_promotion_levels n_lvl
  WHERE
      boa.code = :new.approval
    AND
      bos.code = boa.scheme
    AND
      op.code = bos.operation
    AND
      cs.code = op.current_state
    AND
      ns.code (+)= op.next_state
    AND
      c_lvl.code = cs.promlevel
    AND
      n_lvl.code (+)= ns.promlevel;

  -- если это конструкторское извещение, и происходит продвижение объекта
  -- с "Проектирование" на "Проектирование"...
  IF l_boType = 50
    AND l_current_state = 'Проектирование'
    AND l_next_state = 'Проектирование' THEN

    -- получение кода атрибута "MSG_WARNING"
    SELECT
      Max(code)
    INTO
      l_msg_warning
    FROM
      obj_attributes
    WHERE
        objType = 51
      AND
        shortName = 'MSG_WARNING';

    IF l_msg_warning IS NULL THEN RAISE l_not_found_attribute; END IF;

    -- далее запрос в цикле отбирает все элементы извещения и проверяет
    -- наличие других ревизий объекта на указанных уровнях продвижения;
    -- если элемент извещения - групповая спецификация, то ее содержимое
    -- раскрывается. При этом, в сообщение записывается исполнение
    -- элемента групповой спецификации по шаблону "-[цифра][цифра]".
    -- Если элемент не удоволетворяет шаблону, записывается "-00".
    FOR i IN (
      SELECT
        kiCode,
        listAgg(
          CASE
            WHEN cnt_rev > 1 THEN messagePart
            ELSE NULL
          END, '; '
          ) within GROUP (ORDER BY itemFlag) AS msg_warning
      FROM
        (
        SELECT
          d.kiCode,
          d.itemFlag,
          d.itemSign,
          bo_rev.prodCode,
          d.itemSign || '{' ||
            listAgg(bo_rev.revision, ', ') within GROUP (ORDER BY bo_rev.revision)
            || '}' AS messagePart,
          Count(DISTINCT bo_rev.revision) AS cnt_rev
        FROM
          (
          SELECT
            ki.kiCode AS docCode,
            ki.code AS kiCode,
            ii.itemCode AS itemCode,
            0 AS itemFlag,
            CASE
              WHEN ki.docType IN (7, 23) THEN 'гр. '
              ELSE NULL
            END AS itemSign
          FROM
            ki_item ki,
            ii_items ii
          WHERE
              ii.code = ki.itemCode

          UNION ALL

          SELECT
            ki.kiCode AS docCode,
            ki.code,
            ko.boCode,
            1 AS itemFlag,
            coalesce(regexp_substr(ko.Sign, '-\d{2}$'), '-00') || ' ' AS itemSign
          FROM
            ki_item ki,
            ii_items ii,
            grspc_rel gr,
            konstrobj ko
          WHERE
              ii.code = ki.itemCode
            AND
              ki.docType IN (7,23)
            AND
              gr.grCode = ki.docCode
            AND
              ko.unvCode = gr.code
            AND
              gr.deleteDate IS NULL
          ) d,
          business_objects bo,
          business_objects bo_rev,
          businessobj_promotion bop,
          businessobj_states cs,
          businessobj_promotion_levels lvl
        WHERE
            d.docCode = :new.businessObj
          AND
            bo.code = d.itemCode
          AND
            bo_rev.prodCode = bo.prodCode
          AND
            bop.businessObj = bo_rev.code
          AND
            bop.code = (
              SELECT
                Max(bop_.code)
              FROM
                businessobj_promotion bop_
              WHERE
                  bop_.businessObj = bop.businessObj
            )
          AND
            cs.code = bop.current_state
          AND
            lvl.code = cs.promLevel
          AND
            lvl.name IN ('Проектирование', 'Подготовка производства')
        GROUP BY
          d.kiCode,
          d.itemFlag,
          d.itemSign,
          bo_rev.prodCode
        )
      GROUP BY
        kiCode
    ) LOOP
      -- в цикле обновляется значение атрибута соответствующего элемента
      -- извещения
      EXECUTE IMMEDIATE
        'update obj_attr_values_51 set a_' || l_msg_warning || ' = :1 ' ||
        'where socode = :2'
      USING
        i.msg_warning,
        i.kicode;

    END LOOP;

  END IF;

EXCEPTION
  WHEN l_not_found_attribute THEN
    Raise_Application_Error(-20101, 'Атрибут MSG_WARNING не найден!');
  WHEN OTHERS THEN RAISE;

END;
/