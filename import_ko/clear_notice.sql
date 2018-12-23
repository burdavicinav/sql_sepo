UPDATE konstrobj SET  notice = NULL;
UPDATE documentation SET notice = NULL;
UPDATE spcList SET notice = NULL;
UPDATE details SET notice = NULL;
UPDATE standarts SET notice = NULL;
UPDATE OTHERS SET notice = NULL;
UPDATE spcMaterials SET notice = NULL;
UPDATE specifications SET notice = NULL;

SELECT DISTINCT notice FROM konstrobj;
SELECT * from spcList;
SELECT  *FROM standarts;
SELECT  *FROM OTHERS;
SELECT * FROM sbdraws;
SELECT * FROM specifications;