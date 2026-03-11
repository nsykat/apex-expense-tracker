  


create or replace FUNCTION hash_password (
    p_user_name IN VARCHAR2,
    p_password  IN VARCHAR2,
    p_salt      IN VARCHAR2
) RETURN VARCHAR2 IS
    v_hash VARCHAR2(200);
BEGIN
    -- Call STANDARD_HASH via SQL
    SELECT STANDARD_HASH(p_password || p_salt || p_user_name, 'SHA256')
    INTO v_hash
    FROM dual;

    RETURN v_hash;
END hash_password;
/


create or replace FUNCTION authenticate_user (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN IS
    l_user_name       users.user_name%TYPE := UPPER(p_username);
    l_password        users.password%TYPE;
    l_salt            users.user_salt%TYPE;
    l_active          users.is_active%TYPE;   -- corrected type
    l_hashed_password VARCHAR2(1000);
BEGIN
    -- Fetch user details
    BEGIN
        SELECT password, user_salt, is_active
        INTO l_password, l_salt, l_active
        FROM users
        WHERE user_name = l_user_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            APEX_UTIL.SET_AUTHENTICATION_RESULT(1); -- Unknown username
            RETURN FALSE;
    END;

    -- Block inactive accounts before password check
    IF l_active = 0 THEN
        APEX_UTIL.SET_AUTHENTICATION_RESULT(2); -- Account Locked/Inactive
        RETURN FALSE;
    END IF;

    -- Hash the provided password with the stored salt
    l_hashed_password := hash_password(l_user_name, p_password, l_salt);

    -- Compare hashes
    IF l_hashed_password = l_password THEN
        APEX_UTIL.SET_AUTHENTICATION_RESULT(0); -- Success
        RETURN TRUE;
    ELSE
        APEX_UTIL.SET_AUTHENTICATION_RESULT(4); -- Incorrect password
        RETURN FALSE;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        APEX_UTIL.SET_AUTHENTICATION_RESULT(7); -- Unknown internal error
        APEX_UTIL.SET_CUSTOM_AUTH_STATUS(SQLERRM);
        RETURN FALSE;
END authenticate_user;
/


CREATE SEQUENCE  "USERS_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 19 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

  CREATE TABLE "USERS" 
   (	"USER_ID" NUMBER, 
	"FULLNAME" VARCHAR2(255), 
	"USER_NAME" VARCHAR2(255) NOT NULL ENABLE, 
	"USER_SALT" VARCHAR2(255), 
	"PASSWORD" VARCHAR2(255) NOT NULL ENABLE, 
	"IS_ACTIVE" NUMBER(1,0) DEFAULT 1 NOT NULL ENABLE, 
	"PHONE" VARCHAR2(13), 
	"EMAIL" VARCHAR2(30) NOT NULL ENABLE, 
	 PRIMARY KEY ("USER_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "USERS_U1" UNIQUE ("USER_NAME")
  USING INDEX  ENABLE, 
	 CONSTRAINT "UQ_USERS_PHONE" UNIQUE ("PHONE")
  USING INDEX  ENABLE
   ) ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "USERS_BI" 
BEFORE INSERT ON users
FOR EACH ROW
DECLARE
    v_salt VARCHAR2(20);
BEGIN
    -- Generate primary key if not provided
    IF :NEW.user_id IS NULL THEN
        SELECT users_seq.NEXTVAL INTO :NEW.user_id FROM dual;
    END IF;

    -- Force username to uppercase
    :NEW.user_name := UPPER(:NEW.user_name);

    -- Generate random salt if not provided
    IF :NEW.user_salt IS NULL THEN
        v_salt := DBMS_RANDOM.STRING('x', 20);
        :NEW.user_salt := v_salt;
    END IF;

    -- Ensure is_active defaults to 1
    IF :NEW.is_active IS NULL THEN
        :NEW.is_active := 1;
    END IF;

    -- Hash password securely with SHA-256 and salt
    :NEW.password := hash_password(:NEW.user_name, :NEW.password, :NEW.user_salt);
END;
/
ALTER TRIGGER "USERS_BI" ENABLE;
  CREATE OR REPLACE EDITIONABLE TRIGGER "BU_USERS" 
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- Always keep username uppercase
    :NEW.user_name := UPPER(:NEW.user_name);

    -- Only re-hash if password value is different from the old one
    IF :NEW.password IS NOT NULL AND :NEW.password != :OLD.password THEN
        :NEW.password := hash_password(:NEW.user_name, :NEW.password, :NEW.user_salt);
    ELSE
        :NEW.password := :OLD.password;
    END IF;

    -- Preserve salt unless explicitly changed
    IF :NEW.user_salt IS NULL THEN
        :NEW.user_salt := :OLD.user_salt;
    END IF;
END;
/
ALTER TRIGGER "BU_USERS" ENABLE;
  CREATE OR REPLACE EDITIONABLE TRIGGER "USER_CATEGORY_SEED" 
AFTER INSERT ON users
FOR EACH ROW
BEGIN
  -- Ensure txn_types exist (only insert if not already present)
  MERGE INTO txn_types t
  USING (SELECT 'INCOME' code, 'Income' name FROM dual UNION ALL
         SELECT 'EXPENSE', 'Expense' FROM dual UNION ALL
         SELECT 'DEPOSIT', 'Deposit' FROM dual) src
  ON (t.code = src.code)
  WHEN NOT MATCHED THEN
    INSERT (code, name, added_by)
    VALUES (src.code, src.name, :NEW.user_name);

  -- Income categories
  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Salary', (SELECT id FROM txn_types WHERE code='INCOME'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Freelance', (SELECT id FROM txn_types WHERE code='INCOME'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Investments', (SELECT id FROM txn_types WHERE code='INCOME'), :NEW.user_name);

  -- Expense categories
  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Food', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Transport', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Utilities', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Entertainment', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Healthcare', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Other Expense', (SELECT id FROM txn_types WHERE code='EXPENSE'), :NEW.user_name);

  -- Deposit categories
  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Bank Savings', (SELECT id FROM txn_types WHERE code='DEPOSIT'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Fixed Deposit', (SELECT id FROM txn_types WHERE code='DEPOSIT'), :NEW.user_name);

  INSERT INTO categories (name, type_id, added_by)
  VALUES ('Emergency Fund', (SELECT id FROM txn_types WHERE code='DEPOSIT'), :NEW.user_name);
END;
/
ALTER TRIGGER "USER_CATEGORY_SEED" ENABLE;


  CREATE TABLE "TXN_TYPES" 
   (	"ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE, 
	"CODE" VARCHAR2(20) NOT NULL ENABLE, 
	"NAME" VARCHAR2(50) NOT NULL ENABLE, 
	"ADDED_ON" DATE DEFAULT SYSDATE, 
	"ADDED_BY" VARCHAR2(30), 
	 PRIMARY KEY ("ID")
  USING INDEX  ENABLE, 
	 UNIQUE ("CODE")
  USING INDEX  ENABLE
   ) ;


     CREATE TABLE "CATEGORIES" 
   (	"ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE, 
	"NAME" VARCHAR2(100) NOT NULL ENABLE, 
	"TYPE_ID" NUMBER NOT NULL ENABLE, 
	"ADDED_ON" DATE DEFAULT SYSDATE, 
	"ADDED_BY" VARCHAR2(30), 
	 PRIMARY KEY ("ID")
  USING INDEX  ENABLE
   ) ;

  ALTER TABLE "CATEGORIES" ADD CONSTRAINT "FK_CATEGORY_TYPE" FOREIGN KEY ("TYPE_ID")
	  REFERENCES "TXN_TYPES" ("ID") ENABLE;



  CREATE TABLE "TRANSACTIONS" 
   (	"ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE, 
	"TYPE_ID" NUMBER NOT NULL ENABLE, 
	"CATEGORY_ID" NUMBER NOT NULL ENABLE, 
	"AMOUNT" NUMBER(10,2) NOT NULL ENABLE, 
	"DESCRIPTION" VARCHAR2(400), 
	"TXN_DATE" DATE NOT NULL ENABLE, 
	"ADDED_ON" DATE DEFAULT SYSDATE, 
	"ADDED_BY" VARCHAR2(30), 
	 PRIMARY KEY ("ID")
  USING INDEX  ENABLE
   ) ;

  ALTER TABLE "TRANSACTIONS" ADD CONSTRAINT "FK_TXN_TYPE" FOREIGN KEY ("TYPE_ID")
	  REFERENCES "TXN_TYPES" ("ID") ENABLE;
  ALTER TABLE "TRANSACTIONS" ADD CONSTRAINT "FK_TXN_CATEGORY" FOREIGN KEY ("CATEGORY_ID")
	  REFERENCES "CATEGORIES" ("ID") ENABLE;
