CREATE OR REPLACE TRIGGER tbu_sepo_konstrobj
BEFORE UPDATE ON konstrobj
FOR EACH ROW
WHEN (
    Nvl(OLD.Sign, 0) != Nvl(NEW.Sign, 0)
  OR
    Nvl(OLD.name, 0) != Nvl(NEW.name, 0)
  OR
    Nvl(OLD.notice, 0) != Nvl(NEW.notice, 0)
  OR
    Nvl(OLD.owner, 0) != Nvl(NEW.owner, 0)
  OR
    Nvl(OLD.meascode, 0) != Nvl(NEW.meascode, 0)
  OR
    Nvl(OLD.revision, 0) != Nvl(NEW.revision, 0)
)
DECLARE
  l_checkout NUMBER;
BEGIN
  SELECT checkout INTO l_checkout FROM business_objects
  WHERE
      prodCode = :new.prodCode
    AND
      docCode = :new.unvCode;

  IF l_checkout IS NULL THEN
    Raise_Application_Error(-20110, 'Редактирование объекта невозможно, обратитесь к администратору!');

  END IF;

END;
/

CREATE OR REPLACE TRIGGER tbu_sepo_business_objects
BEFORE UPDATE ON business_objects
FOR EACH ROW
WHEN (Nvl(OLD.revsign, 0) != Nvl(NEW.revsign, 0) AND NEW.checkout IS NULL)
DECLARE

BEGIN
  Raise_Application_Error(-20110, 'Редактирование объекта невозможно, обратитесь к администратору!');
END;
/

SELECT Count(*) FROM konstrobj;

SELECT * FROM business_objects;