-- 2018_06_08_v2 -> 2018_07_08_v1

WHENEVER SQLERROR EXIT;

DECLARE
  l_current_version VARCHAR2(50);
BEGIN
  SELECT property_value INTO l_current_version FROM omp_sepo_properties
  WHERE
      id = 2;

  IF l_current_version != '2018_06_08_v2' THEN
    Raise_Application_Error(-20101, 'Некорректная версия скриптов БД');
  END IF;
END;
/

-- обновление короткого наименования атрибута О_ВО на русскую раскладку
UPDATE obj_attributes
SET
  shortname = 'О_ВО',
  name = 'О_ВО'
WHERE
    shortname IN ('O_BO');

-- исправление ошибки с определением типа атрибутов
CREATE OR REPLACE VIEW v_sepo_std_attr_properties (
  name,
  isnumber,
  isdouble,
  islist
) AS
SELECT
  f.f_longname AS name,
  Min(
    CASE
      WHEN regexp_like(Trim(cs.field_value), '^[-]?\d+$')
        OR cs.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isnumber,
  Min(
    CASE
      WHEN regexp_like(Trim(cs.field_value), '^[-]?\d+([\.,]\d+)?$')
        OR cs.field_value IS NULL THEN 1
      ELSE 0
    END
  ) AS isdouble,
  Min(
    CASE
      WHEN f.f_entermode = 'IEM_LIST' THEN 1
      ELSE 0
    END
  ) AS islist
FROM
  sepo_std_table_rec_contents cs,
  sepo_std_table_fields f
WHERE
    cs.id_field = f.id
  AND
    f.f_entermode IN ('IEM_SIMPLE', 'IEM_LIST')
GROUP BY
  f.f_longname;

CREATE OR REPLACE VIEW v_sepo_std_simple_attrs (
  id_attr,
  id_table,
  field,
  f_datatype,
  f_entermode,
  f_data,
  attr_name,
  omp_type
) AS
SELECT
  f.id AS id_attr,
  f.id_table AS id_table,
  f.field,
  f.f_datatype,
  f.f_entermode,
  f.f_data,
  a.name AS attr_name,
  CASE
    WHEN isnumber = 1 THEN 3
    WHEN isnumber = 0 AND isdouble = 1 THEN 2
    ELSE 1
  END omp_type
FROM
  v_sepo_std_attr_properties a,
  sepo_std_table_fields f
WHERE
    a.islist = 0
  AND
    f.f_longname = a.name
  AND
    f.f_entermode = 'IEM_SIMPLE';

-- обновление структуры БД
EXEC pkg_sepo_import_global.setstdfixobjparams();
EXEC pkg_sepo_import_global.setoldfixobjparams();

-- представление для атрибутов оснастки
DECLARE
  l_table_31 NUMBER;
  l_tblkey_31 NUMBER;
  l_reckey_31 NUMBER;
  l_vo_31 NUMBER;
  l_table_32 NUMBER;
  l_tblkey_32 NUMBER;
  l_reckey_32 NUMBER;
  l_vo_32 NUMBER;
  l_table_33 NUMBER;
  l_tblkey_33 NUMBER;
  l_reckey_33 NUMBER;
  l_vo_33 NUMBER;
BEGIN
  l_table_31 := pkg_sepo_attr_operations.getcode(31, 'Table');
  l_tblkey_31 := pkg_sepo_attr_operations.getcode(31, 'TBLKey');
  l_reckey_31 := pkg_sepo_attr_operations.getcode(31, 'RecKey');
  l_vo_31 := pkg_sepo_attr_operations.getcode(31, 'О_ВО');

  l_table_32 := pkg_sepo_attr_operations.getcode(32, 'Table');
  l_tblkey_32 := pkg_sepo_attr_operations.getcode(32, 'TBLKey');
  l_reckey_32 := pkg_sepo_attr_operations.getcode(32, 'RecKey');
  l_vo_32 := pkg_sepo_attr_operations.getcode(32, 'О_ВО');

  l_table_33 := pkg_sepo_attr_operations.getcode(33, 'Table');
  l_tblkey_33 := pkg_sepo_attr_operations.getcode(33, 'TBLKey');
  l_reckey_33 := pkg_sepo_attr_operations.getcode(33, 'RecKey');
  l_vo_33 := pkg_sepo_attr_operations.getcode(33, 'О_ВО');

  EXECUTE IMMEDIATE
  'create or replace view v_sepo_fixture_attrs as ' ||
  'select socode, objtype, table_, tblkey, reckey, o_vo ' ||
  'from (select ' ||
    'socode,' ||
    'a_' || l_table_31 || ' as table_,' ||
    'a_' || l_tblkey_31 || ' as tblkey,' ||
    'a_' || l_reckey_31 || ' as reckey,' ||
    'a_' || l_vo_31 || ' AS o_vo ' ||
  'from ' ||
    'obj_attr_values_31 ' ||
  'union all ' ||
  'select ' ||
    'socode,' ||
    'a_' || l_table_32 || ' as table_,' ||
    'a_' || l_tblkey_32 || ' as tblkey,' ||
    'a_' || l_reckey_32 || ' as reckey,' ||
    'a_' || l_vo_32 || ' AS o_vo ' ||
  'from ' ||
    'obj_attr_values_32 ' ||
  'union all ' ||
  'select ' ||
    'socode,' ||
    'a_' || l_table_33 || ' as table_,' ||
    'a_' || l_tblkey_33 || ' as tblkey,' ||
    'a_' || l_reckey_33 || ' as reckey,' ||
    'a_' || l_vo_33 || ' AS o_vo ' ||
  'from ' ||
    'obj_attr_values_33),' ||
  'omp_objects ' ||
  'where code = socode';

END;

-- объекты для объединения атрибутов
CREATE TABLE sepo_std_attr_union (
  id NUMBER PRIMARY KEY,
  group_name VARCHAR2(100) UNIQUE NOT NULL
);

CREATE TABLE sepo_std_attr_union_contents (
  id NUMBER PRIMARY KEY,
  id_group NUMBER NOT NULL REFERENCES sepo_std_attr_union(id),
  attr_name VARCHAR2(100) NOT NULL
);

INSERT INTO sepo_std_attr_union
VALUES
(1, 'ДИАМЕТР ПИЛЫ, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(1, 1, 'ДИАМЕТР ПИЛЫ, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(2, 1, 'ДИАМЕТР ПИЛЫ');

INSERT INTO sepo_std_attr_union
VALUES
(2, 'ДИАМЕТР ПОСАДОЧНОГО ОТВЕРСТИЯ, d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(3, 2, 'ДИАМЕТР ПОСАДОЧНОГО ОТВЕРСТИЯ, d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(4, 2, 'ДИАМЕТР ПОСАДОЧНОГО ОТВЕРСТИЯ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(5, 2, 'ДИАМЕТР ПОСАДОЧНОГО ОТВ.');

INSERT INTO sepo_std_attr_union
VALUES
(3, 'ДИАМЕТР РАБОЧЕЙ ЧАСТИ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(6, 3, 'ДИАМЕТР РАБОЧЕЙ ЧАСТИ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(7, 3, 'ДИАМЕТР РАБ. ЧАСТИ');

INSERT INTO sepo_std_attr_union
VALUES
(4, 'ДИАМЕТР РЕЖ. ЧАСТИ, d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(8, 4, 'ДИАМЕТР РЕЖ. ЧАСТИ, d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(9, 4, 'ДИАМЕТР РЕЖУЩЕЙ ЧАСТИ');

INSERT INTO sepo_std_attr_union
VALUES
(5, 'ДИАПАЗОН ИЗМЕРЕНИЙ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(10, 5, 'ДИАПАЗОН ИЗМЕРЕНИЙ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(11, 5, 'ДИАПАЗОН ИЗМЕРЕНИЯ');

INSERT INTO sepo_std_attr_union
VALUES
(6, 'ДЛИНА, l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(12, 6, 'ДЛИНА, l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(13, 6, 'ДЛИНА l');

INSERT INTO sepo_std_attr_union
VALUES
(7, 'ДЛИНА ОБРАБОТКИ l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(14, 7, 'ДЛИНА ОБРАБОТКИ l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(15, 7, 'ДЛИНА ОБРАБОТКИ');

INSERT INTO sepo_std_attr_union
VALUES
(8, 'ДЛИНА РЕЗЦА L');

INSERT INTO sepo_std_attr_union_contents
VALUES
(16, 8, 'ДЛИНА РЕЗЦА L');

INSERT INTO sepo_std_attr_union_contents
VALUES
(17, 8, 'ДЛИНА РЕЗЦА');

INSERT INTO sepo_std_attr_union
VALUES
(9, 'ДЛИНА ФРЕЗЫ, L');

INSERT INTO sepo_std_attr_union_contents
VALUES
(18, 9, 'ДЛИНА ФРЕЗЫ, L');

INSERT INTO sepo_std_attr_union_contents
VALUES
(19, 9, 'ДЛИНА ФРЕЗЫ');

INSERT INTO sepo_std_attr_union
VALUES
(10, 'ЗНАЧЕНИЕ ОТСЧЕТА ПО НОНИУСУ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(20, 10, 'ЗНАЧЕНИЕ ОТСЧЕТА ПО НОНИУСУ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(21, 10, 'ЗНАЧЕНИЕ ОТСЧЕТА ПО НОНИУСУ, "');

INSERT INTO sepo_std_attr_union
VALUES
(11, 'НАРУЖНЫЙ ДИАМЕТР, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(22, 11, 'НАРУЖНЫЙ ДИАМЕТР, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(23, 11, 'НАРУЖНЫЙ ДИАМЕТР');

INSERT INTO sepo_std_attr_union
VALUES
(12, 'КОНУС МОРЗЕ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(24, 12, 'КОНУС МОРЗЕ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(25, 12, 'Конус Морзе');

INSERT INTO sepo_std_attr_union_contents
VALUES
(26, 12, 'КОНУС ИНСТРУМЕНТАЛЬНЫЙ МОРЗЕ');

INSERT INTO sepo_std_attr_union
VALUES
(13, 'НАИМЕНОВАНИЕ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(27, 13, 'НАИМЕНОВАНИЕ');

INSERT INTO sepo_std_attr_union_contents
VALUES
(28, 13, 'НАИМЕН');

INSERT INTO sepo_std_attr_union_contents
VALUES
(29, 13, 'НАИМЕНОВАНИЕ1');

INSERT INTO sepo_std_attr_union
VALUES
(14, 'НОМИН. ТОЛЩИНА ЩУПА');

INSERT INTO sepo_std_attr_union_contents
VALUES
(30, 14, 'НОМИН. ТОЛЩИНА ЩУПА');

INSERT INTO sepo_std_attr_union_contents
VALUES
(31, 14, 'НОМИН. ТОЛЩИНЫ ЩУПОВ');

INSERT INTO sepo_std_attr_union
VALUES
(15, 'ОБЩАЯ ДЛИНА');

INSERT INTO sepo_std_attr_union_contents
VALUES
(32, 15, 'ОБЩАЯ ДЛИНА');

INSERT INTO sepo_std_attr_union_contents
VALUES
(33, 15, 'Общая длина');

--INSERT INTO sepo_std_attr_union
--VALUES
--(16, 'ТИПОРАЗМЕР');

--INSERT INTO sepo_std_attr_union_contents
--VALUES
--(34, 16, 'ТИПОРАЗМЕР');

--INSERT INTO sepo_std_attr_union_contents
--VALUES
--(35, 16, 'ТИПОРАЗМЕР1');

INSERT INTO sepo_std_attr_union
VALUES
(17, 'НОМИНАЛЬНЫЙ ДИАМЕТР, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(36, 17, 'НОМИНАЛЬНЫЙ ДИАМЕТР, D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(37, 17, 'НОМИНАЛЬНЫЙ ДИАМЕТР ВАЛА, D');

INSERT INTO sepo_std_attr_union
VALUES
(18, 'РАЗМЕР D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(38, 18, 'РАЗМЕР D');

INSERT INTO sepo_std_attr_union_contents
VALUES
(39, 18, 'Размер D');

INSERT INTO sepo_std_attr_union
VALUES
(19, 'РАЗМЕР  d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(40, 19, 'РАЗМЕР  d');

INSERT INTO sepo_std_attr_union_contents
VALUES
(41, 19, 'Размер d1');

INSERT INTO sepo_std_attr_union
VALUES
(20, 'СЕЧЕНИЕ РЕЗЦА h*b');

INSERT INTO sepo_std_attr_union_contents
VALUES
(42, 20, 'СЕЧЕНИЕ РЕЗЦА h*b');

INSERT INTO sepo_std_attr_union_contents
VALUES
(43, 20, 'СЕЧЕНИЕ РЕЗЦА (Н*В)');

INSERT INTO sepo_std_attr_union
VALUES
(21, 'РАЗМЕР l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(44, 21, 'РАЗМЕР l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(45, 21, 'РАЗМЕР  l');

INSERT INTO sepo_std_attr_union_contents
VALUES
(46, 21, 'Размер l');

INSERT INTO sepo_std_attr_union
VALUES
(22, 'СПРАВОЧНАЯ ИНФ.');

INSERT INTO sepo_std_attr_union_contents
VALUES
(47, 22, 'СПРАВОЧНАЯ ИНФ.');

INSERT INTO sepo_std_attr_union_contents
VALUES
(48, 22, 'СПРАВОЧН.ИНФ.');

INSERT INTO sepo_std_attr_union_contents
VALUES
(49, 22, 'Справка');

CREATE OR REPLACE VIEW v_sepo_tech_processes_base
AS
SELECT
  tp.id,
  tp.kind,
  tp.key_,
  tp.designation,
  tp.name,
  tp.doc_id,
  Count(DISTINCT t.key_) AS dce_cnt,
  coalesce(Sum(ti.dce_cnt_tp), 0) AS dce_cnt_tp
FROM
  sepo_tech_processes tp
  left JOIN
  sepo_tp_to_dce t
  ON
      t.id_tp = tp.id
  left JOIN
  (
    SELECT
      d.key_,
      Count(DISTINCT t.id) AS dce_cnt_tp
    FROM
      sepo_tp_to_dce d
      JOIN
      sepo_tech_processes t
      ON
          d.id_tp = t.id
    WHERE
        d.designation IS NOT NULL
    GROUP BY
      d.key_
  ) ti
  ON
      ti.key_ = t.key_
GROUP BY
  tp.id,
  tp.kind,
  tp.key_,
  tp.designation,
  tp.name,
  tp.doc_id;

CREATE OR REPLACE VIEW v_sepo_tech_processes
AS
SELECT
  t.id,
  t.kind,
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  t.dce_cnt,
  t.dce_cnt_tp,
  CASE
    WHEN t.kind = 1 AND t.dce_cnt <= 1 AND t.dce_cnt_tp > 1 THEN 0
    WHEN t.kind = 1 AND t.dce_cnt <= 1 AND t.dce_cnt_tp <= 1 THEN 2
    WHEN t.kind = 6 THEN 1
    WHEN t.kind = 7 OR dce_cnt > 1 THEN 3
  END tptype,
  regexp_replace(c.comment_, '^0\s+', '') AS remark
FROM
  v_sepo_tech_processes_base t
  left JOIN
  sepo_tp_comments c
  ON
      c.id_tp = t.id;

CREATE TABLE sepo_tp_error_causes (
  id NUMBER PRIMARY KEY,
  cause VARCHAR2(1000) UNIQUE NOT NULL
);

CREATE TABLE sepo_tp_errors (
  id_tp NUMBER PRIMARY KEY,
  id_cause NUMBER NOT NULL REFERENCES sepo_tp_error_causes(id),
  notice VARCHAR2(1000) NULL,
  FOREIGN KEY (id_tp) REFERENCES sepo_tech_processes(id)
);

INSERT INTO sepo_tp_error_causes
VALUES (1, 'Не указано или не найдено изделие');

INSERT INTO sepo_tp_error_causes
VALUES (2, 'Отсутствуют операции');

INSERT INTO sepo_tp_error_causes
VALUES (3, 'ТП создан сотрудниками бюро САПР');

INSERT INTO sepo_tp_error_causes
VALUES (4, 'Не задан или не найден цех');

INSERT INTO sepo_tp_error_causes
VALUES (5, 'Не указана или не найдена операция');

CREATE OR REPLACE VIEW v_sepo_tp_errors
AS
SELECT
  t.id,
  t.key_,
  t.designation,
  t.name,
  t.doc_id,
  c.id AS id_cause,
  c.cause,
  e.notice
FROM
  sepo_tp_errors e,
  sepo_tech_processes t,
  sepo_tp_error_causes c
WHERE
    e.id_tp = t.id
  AND
    e.id_cause = c.id
ORDER BY
  t.designation;

CREATE TABLE sepo_tp_exclude_authors (
  id NUMBER PRIMARY KEY,
  author VARCHAR2(100) UNIQUE NOT NULL
);

INSERT INTO sepo_tp_exclude_authors VALUES (1, 'ЗИЗЕВСКАЯ');
INSERT INTO sepo_tp_exclude_authors VALUES (2, 'ЕРЕМЕНКО');
INSERT INTO sepo_tp_exclude_authors VALUES (3, 'ЛИТВИНЕНКО');
INSERT INTO sepo_tp_exclude_authors VALUES (4, 'БЕЛОВА');
INSERT INTO sepo_tp_exclude_authors VALUES (5, 'СИСТЕМНЫЙ АДМИНИСТРАТОР');

CREATE OR REPLACE VIEW v_sepo_tp_opers
AS
SELECT
  op.id AS id_op,
  op.id_tp,
  op.key_,
  op.reckey,
  op.order_,
  op.date_,
  op.num,
  op.place,
  op.tpkey,
  f1.f_value AS opercode,
  f2.f_value AS opername,
  f3.f_value AS cex,
  f4.f_value AS instruction,
  regexp_replace(c.comment_, '^0\s+', '') AS remark,
  top.code AS topcode,
  w.code AS wscode
FROM
  sepo_tp_opers op
  left JOIN
  sepo_tp_oper_comments c
  ON
      c.id_oper = op.id
  left JOIN
  sepo_tp_oper_fields f1
  ON
      f1.id_oper = op.id
    AND
      f1.field_name = 'Копк'
  left JOIN
  sepo_tp_oper_fields f2
  ON
      f2.id_oper = op.id
    AND
      f2.field_name = 'ОПЕР'
  left JOIN
  sepo_tp_oper_fields f3
  ON
      f3.id_oper = op.id
    AND
      f3.field_name = 'ЦЕХ'
  left JOIN
  sepo_tp_oper_fields f4
  ON
      f4.id_oper = op.id
    AND
      f4.field_name = 'К_тб'
  left JOIN
  technology_operations top
  ON
      top.description = op.reckey
  left JOIN
  divisionobj d
  ON
      d.division_type = 104
    AND
      d.wscode = f3.f_value
  left JOIN
  workshops w
  ON
      w.dobjcode = d.code;

CREATE OR REPLACE VIEW v_sepo_tp_workers
AS
SELECT
  w.id,
  w.id_tp,
  w.id_op,
  w.id_step,
  w.key_,
  w.reckey,
  w.tblkey,
  w.order_,
  w.date_,
  w.kind,
  w.count_,
  w.operkey,
  w.perehkey,
  f1.f_value AS profcode,
  f2.f_value AS profname,
  f3.f_value AS category,
  f4.f_value AS cnt,
  p.code AS ompcode
FROM
  sepo_tp_workers w
  left JOIN
  sepo_tp_worker_fields f1
  ON
      f1.id_worker = w.id
    AND
      f1.field_name = 'КПи'
  left JOIN
  sepo_tp_worker_fields f2
  ON
      f2.id_worker = w.id
    AND
      f2.field_name = 'NIsp'
  left JOIN
  sepo_tp_worker_fields f3
  ON
      f3.id_worker = w.id
    AND
      f3.field_name = 'Ри'
  left JOIN
  sepo_tp_worker_fields f4
  ON
      f4.id_worker = w.id
    AND
      f4.field_name = 'CIsp'
  left JOIN
  professions p
  ON
      p.profcode = f1.f_value;

CREATE OR REPLACE VIEW v_sepo_eqp_models_omp
AS
SELECT
  t1.f_level,
  t2.omplevel,
  m.code AS ompcode
FROM
  (
  SELECT
    f_level,
    f_name,
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', 'ЕТОРАНКХСВМ')
      AS groupname
  FROM
    v_sepo_eqp_models
  ) t1
  JOIN
  (
  SELECT
    Min(f_level) AS omplevel,
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', 'ЕТОРАНКХСВМ')
      AS groupname
  FROM
    v_sepo_eqp_models
  GROUP BY
    Translate(regexp_replace(f_name, '\W', ''), 'ETOPAHKXCBM', 'ЕТОРАНКХСВМ')
  ) t2
  ON
      t1.groupname = t2.groupname
  JOIN
  equipment_model m
  ON
      m.Sign = t2.omplevel;

CREATE OR REPLACE VIEW v_sepo_tp_equipments
AS
SELECT
  e.id,
  e.id_tp,
  e.id_op,
  e.operkey,
  e.reckey,
  e.invnom,
  m.ompcode
FROM
  sepo_tp_equipments e
  left JOIN
  v_sepo_eqp_models_omp m
  ON
      m.f_level = e.reckey;

CREATE OR REPLACE VIEW v_sepo_tp_tools
AS
SELECT
  t.id,
  t.id_tp,
  t.operkey,
  t.perehkey,
  t.key_,
  t.order_,
  t.date_,
  t.kind,
  t.count_,
  t.reckey AS catalog,
  f1.f_value AS reckey,
  t.tblkey,
  f2.f_value AS o_vo
FROM
  sepo_tp_tools t
  left JOIN
  sepo_tp_tool_fields f1
  ON
    f1.id_tool = t.id
  AND
    f1.field_name = 'OsRc'
  left JOIN
  sepo_tp_tool_fields f2
  ON
    f2.id_tool = t.id
  AND
    f2.field_name = 'О_ВО';

SELECT
  s.*,
  f1.f_value AS pname,
  f2.f_value AS pnum,
  c.comment_--,
--  os.code
FROM
  sepo_tp_steps s
  left JOIN
  sepo_tp_step_fields f1
  ON
      f1.id_step = s.id
    AND
      f1.field_name = 'Тепр'
  left JOIN
  sepo_tp_step_fields f2
  ON
      f2.id_step = s.id
    AND
      f2.field_name = 'Nпер'
  left JOIN
  sepo_tp_step_comments c
  ON
      c.id_step = s.id
--  left JOIN
--  technological_steps os
--  ON
--      os.name = f1.f_value;
WHERE
    NOT EXISTS (
      SELECT 1 FROM sepo_tech_steps
      WHERE
          f_level = reckey
    );

CREATE GLOBAL TEMPORARY TABLE sepo_tp_opers_temp (
  id_op NUMBER,
  id_tp NUMBER,
  key_ NUMBER,
  reckey NUMBER,
  order_ NUMBER,
  date_ VARCHAR2(50),
  num VARCHAR2(50),
  place NUMBER,
  tpkey NUMBER,
  opercode VARCHAR2(50),
  opername VARCHAR2(1000),
  cex VARCHAR2(50),
  instruction NUMBER,
  remark CLOB,
  topcode NUMBER,
  wscode NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_tp_instructions_temp (
  stdcode NUMBER,
  f_level NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_tp_workers_temp (
  ompcode NUMBER,
  category NUMBER,
  cnt NUMBER,
  operkey NUMBER,
  perehkey NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE sepo_tp_equipments_temp (
  ompcode NUMBER,
  operkey NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE OR REPLACE VIEW v_sepo_std_dop_data
AS
SELECT
  g.id_record,
  n.field_value AS name,
  v.field_value AS sign_vo,
  n2.field_value AS name_vo
FROM
  (
  SELECT
    fr.id_record,
    coalesce(fr.id_tool, -1) AS id_tool
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Полное наименование',
        'Обозначение для ВО',
        'Наименование для ВО'
      )
  GROUP BY
    fr.id_record,
    fr.id_tool
  ) g
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Полное наименование'
      )
  ) n
  ON
      g.id_record = n.id_record
    AND
      g.id_tool = n.id_tool
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Обозначение для ВО'
      )
  ) v
  ON
      g.id_record = v.id_record
    AND
      g.id_tool = v.id_tool
  left JOIN
  (
  SELECT
    fr.id_record,
    fr.id_field,
    coalesce(fr.id_tool, -1) AS id_tool,
    fr.field_value
  FROM
    sepo_std_formulas fr,
    sepo_std_table_fields f
  WHERE
      fr.id_field = f.id
    AND
      f.f_longname IN (
        'Наименование для ВО'
      )
  ) n2
  ON
      g.id_record = n2.id_record
    AND
      g.id_tool = n2.id_tool
GROUP BY
  g.id_record,
  n.field_value,
  v.field_value,
  n2.field_value;

CREATE OR REPLACE VIEW v_sepo_std_import
AS
SELECT
  r.id AS id_record,
  pr.id AS id_parent_record,
  f.lvl_classify,
  f.lvl_type,
  pr.f_level,
  pr.f_key AS reckey,
  r.f_key AS tblkey,
  t.f_table,
  d.name,
  d.sign_vo,
  d.name_vo,
  sh.omp_name AS scheme_name,
  g.gost
FROM
  sepo_std_table_records r
  JOIN
  sepo_std_tables t
  ON
      r.id_table = t.id
  JOIN
  sepo_std_records pr
  ON
      pr.id_table = r.id_table
  JOIN
  v_sepo_std_folders f
  ON
      pr.f_level = f.lvl
  left JOIN
  v_sepo_std_dop_data d
  ON
    r.id = d.id_record
  JOIN
  v_sepo_std_gosts g
  ON
    g.id_record = r.id
  JOIN
  v_sepo_std_schemes sh
  ON
      sh.id_record = pr.id;

ALTER TABLE sepo_std_import_temp ADD name_vo VARCHAR2(200);

UPDATE omp_sepo_properties
SET
  property_value = '2018_07_08_v1'
WHERE
    id = 2;