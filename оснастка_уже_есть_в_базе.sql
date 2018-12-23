SELECT * FROM v_sepo_fixture_nodes_load
WHERE
    EXISTS
    (
      SELECT 1 FROM bo_production
      WHERE
          TYPE = 31
        AND
          Sign = designation
    );

SELECT * FROM v_sepo_fixture_load
WHERE
    EXISTS
    (
      SELECT 1 FROM bo_production
      WHERE
          TYPE = 32
        AND
          Sign = designation
    );