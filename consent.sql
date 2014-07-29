-- MINI HL7 RIM for purpose of review row level security
-- no healthcare datatypes
-- very limited amount of classes

DROP SCHEMA IF EXISTS hl7 CASCADE;
DROP ROLE IF EXISTS henry;
-- DROP ROLE IF EXISTS sigmund;
DROP ROLE IF EXISTS pete;

/* The users that will access the application */
CREATE ROLE pete;

CREATE SCHEMA hl7;
GRANT USAGE ON SCHEMA hl7 TO public;

SET search_path = hl7;

DROP SEQUENCE IF EXISTS seq CASCADE;
DROP TABLE IF EXISTS entity CASCADE;
DROP TABLE IF EXISTS role CASCADE;
DROP TABLE IF EXISTS act CASCADE;
DROP TABLE IF EXISTS participation CASCADE;
DROP TABLE IF EXISTS act_relationship CASCADE;

DROP TYPE IF EXISTS entityclasscode;
DROP TYPE IF EXISTS organizationindustrycode;
DROP TYPE IF EXISTS roleclasscode;
DROP TYPE IF EXISTS patientvipcode;
DROP TYPE IF EXISTS actclasscode;
DROP TYPE IF EXISTS actmoodcode;
DROP TYPE IF EXISTS jobcodetype;
DROP TYPE IF EXISTS confidentialitycode;
DROP TYPE IF EXISTS participationtype;
DROP TYPE IF EXISTS statuscode;
DROP TYPE IF EXISTS actreltype;

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
       'act',     -- ? TODO not sure
       'cons',    -- consent
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
       'rcv',    -- receiver (patient about which the record is about)
       'ent',    -- enterer
       'la',     -- legal authenticator
       'ircp'    -- Information Recipient
);

CREATE TYPE confidentialitycode AS ENUM (
       'n',     -- normal
       'r',     -- restricted
       'v'      -- very restricted
);

CREATE TYPE statuscode AS ENUM (
       'active',     
       'completed',  
       'new',     
       'cancelled',
       'aborted',
       'suspended',
       'held'
);
CREATE TYPE actreltype AS ENUM (
      'comp', -- for more see View->types->ActRelationshipsType (http://hl7-vocabulary.pilotfishtechnology.com/HL7/)
      'auth',
      'apnd'
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

CREATE TABLE patient (vipcode patientvipcode) INHERITS (role);
CREATE TABLE employee (jobcode text, pgname text) INHERITS (role);
CREATE TABLE assigned_entity (jobcode text, pgname text) INHERITS (role); 

CREATE TABLE act (
       id                     int PRIMARY KEY DEFAULT nextval('seq'),
       classcode              actclasscode NOT NULL,
       moodcode               actmoodcode NOT NULL,
       code                   text,
       from_time              DATE,
       to_time                DATE,
       status_cd              statuscode,    
       confidentiality_cd     confidentialitycode
       );

CREATE TABLE care_provision () INHERITS (act); -- used for stating that a patient is under care provision
CREATE TABLE observation (value text) INHERITS (act);
CREATE TABLE observation_action () INHERITS (observation);
CREATE TABLE observation_related_problem () INHERITS (observation);
CREATE TABLE substanceadministration (dosequantity numeric) INHERITS (act);
CREATE TABLE consent() INHERITS (act);
CREATE TABLE consent_directive() INHERITS (act);

CREATE TABLE act_relationship (
       id                     int PRIMARY KEY DEFAULT nextval('seq'),
       act_id_source          int NOT NULL,
       act_id_target          int NOT NULL,
       type_cd                actreltype
       );

CREATE TABLE participation (
       id       int PRIMARY KEY DEFAULT nextval('seq'),
       act      int, -- references act(id)
       role     int, -- references role(id)
       typecode participationtype,
       from_time            DATE,
       to_time              DATE
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
act_consent int;
act_consent_dir int;
obs_action  int;
obs_rel_problem int;
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
EXECUTE 'INSERT INTO care_provision (classcode, moodcode, code, from_time, to_time, confidentiality_cd)
        VALUES (''pcpr'', ''evn'', ''diabetes'', ''20120908'', NULL, ''r'') RETURNING id' INTO act1;

EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''rcv'', ''20121108'', NULL) RETURNING id' USING act1, pat_mary;

/* Dr Pete is a physician */
EXECUTE 'INSERT INTO person (classcode, name)
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
-- EXECUTE 'INSERT INTO person (classcode, name)
--         VALUES (''psn'', ''Dr. Ronan Blue'') RETURNING id' INTO ronan;
-- EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
--         VALUES (''emp'', $1, $2, ''20131108'', NULL, ''n'',''doc'', ''ronan'')
--         RETURNING id' USING ronan, org1 INTO emp_ronan;
-- EXECUTE 'INSERT INTO employee (classcode, player, scoper, from_time, to_time, confidentiality_cd, jobcode, pgname)
--         VALUES (''emp'', $1, $2, ''20131108'', NULL, ''n'', ''res'', ''ronan'')
--         RETURNING id' USING ronan, org1 INTO emp_ronan_r;


/* Mary White releases a consent through (helped by) Dr. Pete */
EXECUTE 'INSERT INTO consent (classcode, moodcode, code, from_time, to_time, status_cd, confidentiality_cd) VALUES (''cons'', ''evn'', ''ConsentTODOFINDTHECODE'', ''20120909'', ''20120909'', ''completed'', ''r'') RETURNING id' INTO act_consent;

-- patient who gives consent
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''rcv'', ''20120909'', NULL) RETURNING id' USING act_consent, pat_mary;

-- author of the act (implicit the custodian)
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''prf'', ''20120909'', NULL) RETURNING id' USING act_consent, aen_pete;

-- the definition of the structured consent, pou: treatment
EXECUTE 'INSERT INTO consent_directive (classcode, moodcode, code, from_time, to_time, status_cd, confidentiality_cd) VALUES (''act'', ''def'', ''TREAT'', ''20120909'', ''20120909'', ''active'', ''r'') RETURNING id' INTO act_consent_dir;

-- the person who is the receipient of the consent (in this case the attending physician)
EXECUTE 'INSERT INTO participation (act, role, typecode, from_time, to_time)
        VALUES ($1, $2, ''ircp'', ''20120909'', NULL) RETURNING id' USING act_consent_dir, aen_pete;

-- the definition of the consent
-- EXECUTE 'INSERT INTO observation (classcode, moodcode, code, from_time, to_time, status_cd, confidentiality_cd) VALUES (''obs'', ''def'', ''TREAT'', ''20120909'', ''20120909'', ''active'', ''r'') RETURNING id' INTO act_consent_dir;

-- the action 
EXECUTE 'INSERT INTO observation_action (classcode, moodcode, code, from_time, to_time, status_cd, confidentiality_cd, value) VALUES (''obs'', ''def'', ''IDISCL'', NULL, NULL, NULL, ''r'',  NULL) RETURNING id' INTO obs_action;

-- the related problem
EXECUTE 'INSERT INTO observation_related_problem (classcode, moodcode, code, from_time, to_time, status_cd, confidentiality_cd, value) VALUES (''obs'', ''def'', ''PrincipalDiagnosisCODE:8319008'', ''20120909'', ''20120909'', NULL, ''r'',  ''Portavita174'') RETURNING id' INTO obs_rel_problem;


EXECUTE 'INSERT INTO act_relationship (act_id_source, act_id_target, type_cd) 
         VALUES ($1, $2, ''comp'') RETURNING id' USING act_consent_dir, obs_action;

EXECUTE 'INSERT INTO act_relationship (act_id_source, act_id_target, type_cd) 
         VALUES ($1, $2, ''comp'') RETURNING id' USING act_consent_dir, obs_rel_problem;
         
EXECUTE 'INSERT INTO act_relationship (act_id_source, act_id_target, type_cd) 
         VALUES ($1, $2, ''comp'') RETURNING id' USING act_consent, act_consent_dir;

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

\echo ======= ACT RELATIONSHIP =======
SELECT * FROM act_relationship;

\quit