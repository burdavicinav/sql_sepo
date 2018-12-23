SELECT
  -- ������� ����������� ���������
  mat_data.matSign,
  -- ������ ���������
  lvl_mat.name AS matStatus,
  -- ������������
  mat_data.spcSign,
  -- ������ ������������
  lvl_spc.name AS spcStatus,
  -- ����� ������� � ������������
  mat_data.position,
  -- ����������� ���������, �������������� �� �������
  mat_data.correctMatSign
FROM
  (
  SELECT
    ko.unvCode AS matCode,
    ko.prodCode AS matProdCode,
    ko.Sign AS matSign,
    ko.name AS matName,
    spc.unvCode AS spcCode,
    spc.prodCode AS spcProdCode,
    spc.Sign AS spcSign,
    sp.position,
    -- ������� ������������ ����������� ���������� ���������
    CASE
      WHEN spc.unvCode IS NOT NULL THEN spc.Sign || '-' || sp.position || 'M'
      ELSE
        NULL
    END correctMatSign
  FROM
    konstrobj ko,
    specifications sp,
    konstrobj spc
  WHERE
      ko.unvCode = sp.code(+)
    AND
      sp.spcCode = spc.unvCode(+)
    AND
      -- ��������� ���������
      ko.itemType = 5
  ) mat_data,
  business_objects bo_mat,
  businessObj_promotion bop_mat,
  businessObj_states bs_mat,
  businessObj_promotion_levels lvl_mat,
  business_objects bo_spc,
  businessObj_promotion bop_spc,
  businessObj_states bs_spc,
  businessObj_promotion_levels lvl_spc
WHERE
    bo_mat.docCode = mat_data.matCode
  AND
    bo_mat.prodCode = mat_data.matProdCode
  AND
    bop_mat.businessObj = bo_mat.code
  AND
    bop_mat.code = (
      SELECT Max(bop_.code) FROM businessObj_promotion bop_
      WHERE
          bop_.businessObj = bop_mat.businessObj
    )
  AND
    bs_mat.code = bop_mat.current_state
  AND
    lvl_mat.code = bs_mat.promLevel
  AND
    bo_spc.docCode = mat_data.spcCode
  AND
    bo_spc.prodCode = mat_data.spcProdCode
  AND
    bop_spc.businessObj = bo_spc.code
  AND
    bop_spc.code = (
      SELECT Max(bop_.code) FROM businessObj_promotion bop_
      WHERE
          bop_.businessObj = bop_spc.businessObj
    )
  AND
    bs_spc.code = bop_spc.current_state
  AND
    lvl_spc.code = bs_spc.promLevel
  AND
    -- �� ����� �������������� �������
    lvl_mat.name != '������������'
  AND
    lvl_spc.name != '������������'
  AND
    -- ����������� ��������� �� ��������� � ����������
    mat_data.matSign != mat_data.correctMatSign
ORDER BY
  matSign;