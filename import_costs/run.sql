BEGIN
  -- ���������� ��������� ��� ����������, ��� � ���
  pkg_sepo_attr_operations.CreateAttrView('view_sepo_material_attrs', 1000001);
  pkg_sepo_attr_operations.CreateAttrView('view_sepo_tmc_attrs', 1000045);
  pkg_sepo_attr_operations.CreateAttrView('view_sepo_pki_attrs', 4);

  -- ���������� ���� ���� "������"
  pkg_sepo_prices.AddPriceType('������', '10');

  -- ������� ���
  FOR i IN (
    -- ���������
    SELECT
      so_.code AS soCode,
      mat.recDate,
      unit.shortName AS unit,
      attrs.CENN AS price
    FROM
      materials mat,
      stockobj so_,
      measures unit,
      view_sepo_material_attrs attrs
    WHERE
        so_.fk_materials = mat.code
      AND
        mat.measCode = unit.code
      AND
        mat.soCode = attrs.soCode
      AND
        attrs.CENN > 0

    -- ���
    UNION ALL

    SELECT
      so_.code AS soCode,
      oth.recDate,
      unit.shortName AS unit,
      attrs.CENN AS price
    FROM
      stock_other oth,
      stockobj so_,
      measures unit,
      view_sepo_tmc_attrs attrs
    WHERE
        so_.fk_stockOther = oth.code
      AND
        oth.measCode = unit.code
      AND
        oth.code = attrs.soCode
      AND
        attrs.CENN > 0

    -- ���
    UNION ALL

    SELECT
      so_.code AS soCode,
      ko.recDate,
      unit.shortName AS unit,
      attrs.CENN AS price
    FROM
      konstrobj ko,
      business_objects bo,
      stockobj so_,
      measures unit,
      view_sepo_pki_attrs attrs
    WHERE
        so_.unvCode = ko.unvCode
      AND
        bo.docCode = ko.unvCode
      AND
        bo.prodCode = ko.prodCode
      AND
        ko.measCode = unit.code
      AND
        bo.code = attrs.soCode
      AND
        attrs.CENN > 0
  ) LOOP

    -- �������� ����
    pkg_sepo_prices.CreatePrice(
      '������',
      i.soCode,
      i.unit,
      i.price,
      'RUR',
      i.recDate
      );

  END LOOP;

END;
/