-- загруженная спецоснастка
SELECT
  bo_sp.doccode AS spccode,
  bo_sp.name,
  bo_sp.today_statedate
FROM
  sepo_osn_sostav sp,
  v_sepo_search_omega_link sl,
  business_objects bo_sp
WHERE
    sl.art_id = sp.proj_aid
  AND
    bo_sp.code = sl.bocode
  AND
    bo_sp.TYPE = 31
GROUP BY
  bo_sp.doccode,
  bo_sp.name,
  bo_sp.today_statedate;

-- удаление состава
DELETE FROM specifications s
WHERE
    s.spccode IN (
      SELECT
        bo_sp.doccode
      FROM
        sepo_osn_sostav sp,
        v_sepo_search_omega_link sl,
        business_objects bo_sp
      WHERE
          sl.art_id = sp.proj_aid
        AND
          bo_sp.code = sl.bocode
        AND
          bo_sp.TYPE = 31
      GROUP BY
        bo_sp.doccode
    );