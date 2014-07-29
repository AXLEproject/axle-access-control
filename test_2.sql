
-- MINI HL7 RIM for purpose of review row level security
-- no healthcare datatypes
-- very limited amount of classes

DROP SCHEMA IF EXISTS hl7 CASCADE;
DROP ROLE IF EXISTS henry;
DROP ROLE IF EXISTS sigmund;
DROP ROLE IF EXISTS pete;

/* The users that will access the application */
CREATE ROLE henry;
CREATE ROLE sigmund;
CREATE ROLE pete;

CREATE SCHEMA hl7;
GRANT USAGE ON SCHEMA hl7 TO public;

SET search_path = hl7;

DROP SEQUENCE IF EXISTS seq CASCADE;
DROP TABLE IF EXISTS entity CASCADE;
DROP TABLE IF EXISTS role CASCADE;
DROP TABLE IF EXISTS act CASCADE;
DROP TABLE IF EXISTS participation CASCADE;
DROP TYPE IF EXISTS entityclasscode;
DROP TYPE IF EXISTS organizationindustrycode;
DROP TYPE IF EXISTS roleclasscode;
DROP TYPE IF EXISTS patientvipcode;
DROP TYPE IF EXISTS actclasscode;
DROP TYPE IF EXISTS actmoodcode;
DROP TYPE IF EXISTS confidentialitycode;
DROP TYPE IF EXISTS participationtype;

CREATE SEQUENCE seq;

/* In this mini-example, each inheritance child has exactly one corresponding
class code, for instance 'organization' has the associated classcode 'org'. In
the full RIM, there is a hierarchy in classcodes, where for instance 'org' is
specialized into 'state', 'pub' and 'nat', so the classcode gives more detailed
information about what kind of class the row describes, than can be inferred
from the inheritance child table alone. */
CREATE TYPE entityclasscode AS ENUM (
       'psn', -- person
       'org' -- organization
);

/* The real NAICS codesystem uses numbers. For this example, mnemonics are used
instead. */
CREATE TYPE organizationindustrycode AS ENUM (
       'fam',  -- family planning center
       'hos',  -- hospital
       'psah', -- psychiatric and substance abuse hospitals
       'omhs'  -- offices of mental health specialists
);

CREATE TYPE roleclasscode AS ENUM (
       'pat',     -- person
       'emp',     -- employee
       'aen'      -- assigned entity
);
CREATE TYPE patientvipcode AS ENUM (
       'bm',     -- board member
       'vip',    -- very important person
       'for'     -- foreign dignitary
);

CREATE TYPE actclasscode AS ENUM (
       'obs',    -- observation
       'sbadm',  -- substance administration
       'pcpr',   -- care provision
       'enc'     -- encounter
);

CREATE TYPE actmoodcode AS ENUM (
       'def',    -- definition
       'evn',    -- event
       'gol',    -- goal
       'rqo',    -- request or order
       'apt'     -- appointment
);

CREATE TYPE jobcodetype AS ENUM (
       'doc',    -- doctor
       'int',    -- intern doctor
       'nur',    -- nurse
       'res',    -- researcher
       'adm'     -- administration
);

CREATE TYPE participationtype AS ENUM (
       'prf',    -- performer
       'rcv',     -- receiver (patient about which the record is about)
       'ent',     -- enterer
       'la'       -- legal authenticator
);

CREATE TYPE confidentialitycode AS ENUM (
       'n',     -- normal
       'r',     -- restricted
       'v'     -- very restricted
);


CREATE TABLE entity (
       id        int PRIMARY KEY DEFAULT nextval('seq'),
       classcode entityclasscode NOT NULL,
       name      text);
CREATE TABLE person (birthtime timestamp) INHERITS (entity);
CREATE TABLE organization (industrycode organizationindustrycode) INHERITS (entity);

CREATE TABLE role (
       id         int PRIMARY KEY DEFAULT nextval('seq'),
       classcode  roleclasscode NOT NULL,
       player     int NOT NULL, -- references entity(id)
       scoper     int,          -- references entity(id)
       from_time  DATE,
       to_time    DATE,
       confidentiality_cd confidentialitycode
       );

CREATE TABLE patient (id int PRIMARY KEY, vipcode patientvipcode) INHERITS (role);
CREATE TABLE employee (jobcode text, pgname text) INHERITS (role);
CREATE TABLE assigned_entity (jobcode text, pgname text) INHERITS (role);

CREATE TABLE act (
       id                  int PRIMARY KEY DEFAULT nextval('seq'),
       classcode           actclasscode NOT NULL,
       moodcode            actmoodcode NOT NULL,
       code                text,
       from_time           DATE,
       to_time             DATE,
       confidentiality_cd  confidentialitycode,
       clinical_segment    text[]
       );

CREATE TABLE care_provision () INHERITS (act); -- used for stating that a patient is under care provision
CREATE TABLE observation (value text) INHERITS (act);
CREATE TABLE substanceadministration (dosequantity numeric) INHERITS (act);
CREATE TABLE consent(TODO) INHERITS (act);

CREATE TABLE participation (
       id       int PRIMARY KEY DEFAULT nextval('seq'),
       act      int, -- references act(id)
       role     int, -- references role(id)
       typecode participationtype,
       from_time            DATE,
       to_time              DATE
       );

CREATE TABLE consent (
       roleid                int REFERENCES patient(id),
       action                text,
       purposeofuse          text,
       informationreference  text
);

DO $$
DECLARE
mary        int;
bob         int;
isabella    int;
henry       int;
pete        int;
john        int;
ronan       int;
pat_mary    int;
pat_john    int;
pat_isabella int;
emp_bob     int;
emp_henry   int;
emp_ronan   int;
emp_ronan_r int;
emp_pete    int;
aen_pete2    int;
aen_henry   int;
aen_pete    int;
act1        int;
act2        int;
org1        int;
org2        int;
obs1        int;
obs2        int;

BEGIN
/* Use Case 1a */

/* Mary White has been diagnosed diabetes type 2 and starts getting treated at Community Health and Hospitals.
*/
EXECUTE 'INSERT INTO person (classcode, name, birthtime)
        VALUES (''psn'', ''Mary White'', ''19500221'') RETURNING id' INTO mary;

EXECUTE 'INSERT INTO organization (classcode, name, industrycode)
        VALUES (''org'', ''Community Health and Hospitals'', ''hos'') RETURNING id' INTO org1;
-- NB: The patient personal data has no particular access restriction ('n')
EXECUTE 'INSERT INTO patient (classcode, player, scoper, from_time, to_time, confidentiality_cd, vipcode)
        VALUES (''pat'', $1, $2, ''20121108'', NULL, ''n'', NULL) RETURNING id' USING mary, org1 INTO pat_mary;

-- NB: All health data is confidential, so access is restricted 'r'
EXECUTE 'INSERT INTO care_provision (classcode, moodcode, code, from_time, to_time, confidentiality_cd, clinical_segment)
        VALUES (''pcpr'', ''evn'', ''diabetes'', ''20120908'', NULL, ''r'', ''{diabetes}'') RETURNING id' INTO act1;

EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''rcv'', ''20121108'', NULL) RETURNING id' USING act1, pat_mary;

/* Add a blood pressure measurement to the diabetes treatment */
EXECUTE 'INSERT INTO observation (classcode, moodcode, code, confidentialitycode, from_time, to_time, value, clinical_segment)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'',
        ''{n}'', ''20090227 130000'', ''20090227 130000'', 130, ''{diabetes}'') RETURNING id' INTO obs1;

/* Dr Pete is a physician */
EXECUTE  'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Pete Rain'') RETURNING id' INTO pete;

/* He is employeed at the Health and Community Hospitals */
EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''20121108'', NULL, ''n'', ''doc'',''pete'')
        RETURNING id' USING pete, org1 INTO emp_pete;

/* Dr. Pete is the treating physician of Mary White. NB: A nurse can also be an assigned entity */
EXECUTE 'INSERT INTO assigned_entity (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''aen'', $1, $2, ''20131108'', NULL, ''n'', ''doc'', ''pete'')
        RETURNING id' USING pete, org1 INTO aen_pete;

EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''prf'',''20120909'', NULL) RETURNING id' USING act1, aen_pete;

/* RLS: Mary White opts in to allow her data concerning diabetes to be used for research. Doctor Ronan Blue, in addition to treating patients, also performs research */
EXECUTE  'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Ronan Blue'') RETURNING id' INTO ronan;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''20131108'', NULL, ''n'',''doc'', ''ronan'')
        RETURNING id' USING ronan, org1 INTO emp_ronan;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''20131108'', NULL, ''n'', ''res'', ''ronan'')
        RETURNING id' USING ronan, org1 INTO emp_ronan_r;

EXECUTE 'INSERT INTO consent(role_id, action, purpose_of_use)
        VALUES($1, ''allow'', ''research'', ''diabetes'')' USING pat_mary;

/* Here goes RLS: if the user has research capability
AND the acts belong to a patient that has consented for research of diabetes information
AND the acts are in the context of the care provision 'T' for diabetes
*/
 ALTER TABLE act SET ROW SECURITY FOR SELECT TO (
   EXISTS (
/* An employee with research capability */
     SELECT 1
     FROM employee emp
     WHERE emp.pgname = current_user
     AND emp.jobcode='res'
)
);
--     AND
--     SELECT 1
--     LEFT JOIN participation part_pat ON part_pat.act_id=act.id
--     LEFT JOIN patient pat on part_pat.role_id=pat.id
--     LEFT JOIN person pers on pat.id=pers.id
--     WHERE pers.name='Mary White'

--     AND act.classcode='pcpr'
--     AND act.code='evn'
--     AND act.code='T'
-- );

/* Mary has had an affair with Doctor Bob Smith, who also works in this hospital. She wants to prevent him from seeing her records concerning the diabetes treatment.
*/
EXECUTE 'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Bob Smith'') RETURNING id' INTO bob;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''20131108'', NULL, ''n'', ''doc'', ''bob'')
        RETURNING id' USING bob, org1 INTO emp_bob;

/* RLS: if records belong to Mary White and the person who is accessing them is NOT bob */
-- ALTER TABLE act SET ROW SECURITY FOR ALL TO (
--   EXISTS (
--     SELECT 1
--     FROM participation part_pat ON part_pat.act_id=act.id
--     LEFT JOIN patient pat on part_pat.role_id=pat.id
--     LEFT JOIN person pers on pat.id=pers.id
--     WHERE pers.name LIKE 'Mary White'
--     AND current_user IS DISTINCT FROM 'bob'
--     )
-- );
-- TEST PLAN:
/*
Dr Ronan can access her records, only for select
Dr. Bob cannot access her records (both personal and treatment)
Combine with organizational policy, that is, all doctors can view all patients records with security label 'r'
*/

/*------- ORGANIZATIONAL POLICIES ----------- */
/* Isabella Jones is a celebrity. She has birthtime 19750501 and is patient at
 Community Health and Hospitals.
 */
EXECUTE 'INSERT INTO person (classcode, name, birthtime)
        VALUES (''psn'', ''Isabella Jones'', ''19750501'') RETURNING id' INTO isabella;
EXECUTE 'INSERT INTO patient (classcode, player, scoper, from_time, to_time,  confidentiality_cd, vipcode)
        VALUES (''pat'', $1, $2, ''20120908'', NULL, ''v'', ''vip'')
        RETURNING id' USING isabella, org1 INTO pat_isabella;

/* Isabella Jones has had a Colonoscopy treatment. Since she is a celebrity all
information concerning this treatment is classified as very restricted. */
EXECUTE 'INSERT INTO care_provision (classcode, moodcode, code, from_time, to_time, confidentiality_cd)
        VALUES (''pcpr'', ''evn'', ''73761001|Colonoscopy'',
        ''20120908'', ''20120915'', ''v'') RETURNING id' INTO act2;
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''rcv'',''20120908'', ''20120915'')'
        USING act2, pat_isabella;


/* Dr. Henry Seven, working at Community Health and Hospitals, was the
gastroenterologist who performed the Colonoscopy to Mrs. Jones.
*/
EXECUTE 'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Henry Seven'') RETURNING id' INTO henry;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''20120908'', NULL, ''n'', ''doc'', ''henry'')
        RETURNING id' USING henry, org1 INTO emp_henry;
EXECUTE 'INSERT INTO assigned_entity (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''aen'', $1, $2, ''20120908'', NULL, ''v'', ''doc'', ''henry'')
        RETURNING id' USING henry, org1 INTO aen_henry;
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''prf'',''20120908'', ''20120915'') '
        USING act2, aen_henry;

/* Isabella Jones has the pressure measured by Dr. Bob Smith. The observation is very restricted because Isabella Jones is a VIP. */
EXECUTE 'INSERT INTO observation (classcode, moodcode, code, from_time, to_time, confidentiality_cd, value)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'',
        ''20090227 130000'', ''20090227 130000'', ''v'', 130) RETURNING id' INTO obs1;

EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''rcv'',''20120908'', ''20120915'') RETURNING id' USING obs1, pat_isabella;
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''prf'',''20090227 130000'', ''20090227 130000'') RETURNING id' USING obs1, emp_bob;


/* Isabella wants Dr Henry not to be her doctor any more. Instead she chooses Dr. Pete to be in charge of her Colonoscopy treatment (I am assuming colonoscopy is a treatment..) . */
EXECUTE 'UPDATE role SET to_time=''20140303''
         WHERE role.id=$1' USING aen_henry;
EXECUTE 'INSERT INTO assigned_entity (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
        VALUES (''aen'', $1, $2, ''20140303'', NULL, ''v'', ''doc'', ''henry'')
        RETURNING id' USING pete, org1 INTO aen_pete2;

/* Organization rules */
/* 1. All health records classified as restricted. Doctors can access for read/write all patient records labeled as such ('r'). */
-- TODO


/* 2. Some patient records can be labeled as very restricted. VIP or sensitivie treatments. In this case only the treating physician can access them.  */
-- TODO

/* 3. Treating physician has a time validity. When a patient changes the treating physician, the later can only access those records attributed to him. New records are not accessible any longer. */


END;
$$ LANGUAGE plpgsql;

/* Superuser can select all */

\echo ====== ENTITY HIERARCHY ========
SELECT * FROM entity;

\echo ORGANIZATION
SELECT * FROM organization;

\echo PERSON
SELECT * FROM person;

\echo ======= ROLE HIERARCHY ========
SELECT * FROM role;

\echo PATIENT
SELECT * FROM patient;

\echo EMPLOYEE
SELECT * FROM employee;

\echo ======= ACT HIERARCHY ========
SELECT * FROM act;

\echo OBSERVATION
SELECT * FROM observation;

\echo care_provision
SELECT * FROM care_provision;

\echo ======= PARTICIPATION =======
SELECT * FROM participation;

\quit
