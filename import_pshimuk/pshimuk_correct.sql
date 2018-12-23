BEGIN
  -- ����������� �������� �������� ������� ���� � �����;
  -- ���������� ��� �����, ��������� omp_adm;
  -- ��� � ����� ������������ � ���������������� ����������
  -- �� ����� pshimuk.dbf ( ������� sepo_pshimuk );

  -- ����� ��������� ������ � ����� ��������, �����
  -- ���������������� ��������� ��������;
  FOR i IN (
    SELECT
      *
    FROM
      (
      SELECT
        dce.value_,
        ko.Sign,
        ko.name,
        ko.itemType,
        de.matCode,
        m.plCode,
        de.normCode,
        -- ������� ���
        de.pureWeight,
        -- ������ ���: ���� 0, �� 999; ����� - �������� ������� �� 1000
        CASE
          WHEN coalesce(pshimuk.chv, 0 ) = 0 THEN 999
          ELSE
            pshimuk.chv / 1000
        END AS pure_correct,
        -- ������� �����
        de.fullNorm1,
        -- ����� ������� �� 1000
        pshimuk.nr / 1000 AS norm_correct
      FROM
        view_sepo_union_attrs_dce dce,
        business_objects bo,
        konstrobj ko,
        det_expense de,
        materials m,
        (
          SELECT
            shm,
            dce,
            Max(nr) AS nr,
            Max(chv) AS chv
          FROM
            sepo_pshimuk
          GROUP BY
            shm,
            dce
        ) pshimuk
      WHERE
          bo.code = dce.soCode
        AND
          ko.unvCode = bo.docCode
        AND
          de.detCode = ko.unvCode
        AND
          m.code = de.matCode
        AND
          EXISTS
          (
            SELECT 1 FROM det_expense_history h
            WHERE
                h.normCode = de.normCode
              AND
                h.start_user = -2
          )
        AND
          dce.value_ = pshimuk.dce
        AND
          m.plCode = pshimuk.shm
      )
      data
    WHERE
        (
          data.pureWeight != data.pure_correct
        OR
          data.fullnorm1 != data.norm_correct
        )

  ) LOOP
    UPDATE det_expense
    SET
      -- ������ ���
      pureWeight = i.pure_correct,
      -- �����
      fullNorm1 = i.norm_correct
    WHERE
        normCode = i.normCode;

  END LOOP;

END;
/