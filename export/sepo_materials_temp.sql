CREATE GLOBAL TEMPORARY TABLE sepo_materials_temp
(
  soCode NUMBER,
  plCode VARCHAR2(30),
  unit_1 NUMBER,
  unit_2 NUMBER,
  unit_3 NUMBER,
  createDate DATE,
  modifyDate DATE,
  createUser NUMBER,
  modifyUser NUMBER,
  state_old NUMBER,
  state_new NUMBER
) ON COMMIT PRESERVE ROWS;