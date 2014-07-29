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
       'pat',    -- person
       'emp'     -- employee
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


CREATE DOMAIN confidentialitycode AS text
CHECK (
      ARRAY[VALUE] <@ ARRAY[
       'c',      -- celebrity
       's',      -- sensitive
       't',      -- taboo
       'eth',    -- substance abuse related
       'hiv',    -- hiv related
       'psy',    -- psychiatry relate
       'sdv',    -- sexual and domestic violence related
       'l',      -- low
       'n',      -- normal
       'r',      -- restricted
       'v'       -- very restricted
       ]
);

/* work around cannot create array over a domain */
CREATE DOMAIN _confidentialitycode AS text[]
CHECK (
      VALUE <@ ARRAY[
       'c',      -- celebrity
       's',      -- sensitive
       't',      -- taboo
       'eth',    -- substance abuse related
       'hiv',    -- hiv related
       'psy',    -- psychiatry relate
       'sdv',    -- sexual and domestic violence related
       'l',      -- low
       'n',      -- normal
       'r',      -- restricted
       'v'       -- very restricted
       ]
);

CREATE TYPE participationtype AS ENUM (
       'prf',    -- performer
       'rct'     -- record target (patient about which the record is about)
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
       confidentialitycode _confidentialitycode
       );
CREATE TABLE patient (vipcode patientvipcode) INHERITS (role);
CREATE TABLE employee (jobcode text, pgname text) INHERITS (role);

CREATE TABLE act (
       id                  int PRIMARY KEY DEFAULT nextval('seq'),
       classcode           actclasscode NOT NULL,
       moodcode            actmoodcode NOT NULL,
       code                text,
       confidentialitycode _confidentialitycode,
       effectivetime       tsrange);
CREATE TABLE observation (value text) INHERITS (act);
CREATE TABLE substanceadministration (dosequantity numeric) INHERITS (act);

CREATE TABLE participation (
       id       int PRIMARY KEY DEFAULT nextval('seq'),
       act      int, -- references act(id)
       role     int, -- references role(id)
       typecode participationtype);


DO $$
DECLARE
psn1 int;
org1 int;
pat1 int;
act1 int;
psn2 int;
emp1 int;
psn3 int;
pat2 int;
org2 int;
obs1 int;
obs2 int;
pat3 int;
act2 int;
psn4 int;
emp2 int;
BEGIN
/* Example adapted from Consolidated CDA CCD 1.xml */

/* Isabella Jones is a celebrity. She has birthtime 19750501 and is patient at
provider organization Community Health and Hospitals */
EXECUTE 'INSERT INTO person (classcode, name, birthtime)
        VALUES (''psn'', ''Isabella Jones'', ''19750501'') RETURNING id' INTO psn1;
EXECUTE 'INSERT INTO organization (classcode, name, industrycode)
        VALUES (''org'', ''Community Health and Hospitals'', ''hos'') RETURNING id' INTO org1;
EXECUTE 'INSERT INTO patient (classcode, player, scoper, vipcode)
        VALUES (''pat'', $1, $2, ''vip'') RETURNING id' USING psn1, org1 INTO pat1;

/* Isabella Jones has had a Colonoscopy treatment. Since she is a celebrity all
information concerning this treatment is classified as sensitive. */
EXECUTE 'INSERT INTO act (classcode, moodcode, code, confidentialitycode, effectivetime)
        VALUES (''pcpr'', ''evn'', ''73761001|Colonoscopy'',
        ''{c,s}'', ''[20120908, 20120915)'') RETURNING id' INTO act1;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''rct'') RETURNING id' USING act1, pat1;

/* Dr. Henry Seven, working at Community Health and Hospitals, was the
gastroenterologist who performed the procedure above. */
EXECUTE 'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Henry Seven'') RETURNING id' INTO psn2;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''207RG0100X|Gastroenterologist'', ''henry'')
        RETURNING id' USING psn2, org1 INTO emp1;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''prf'') RETURNING id' USING act1, emp1;

/* Another patient John Doe has had his blood pressure observed in Community
Health and Hospitals. */
EXECUTE 'INSERT INTO person (classcode, name, birthtime)
        VALUES (''psn'', ''John Doe'', ''19630401'') RETURNING id' INTO psn3;
EXECUTE 'INSERT INTO patient (classcode, player, scoper, vipcode)
        VALUES (''pat'', $1, $2, NULL) RETURNING id' USING psn3, org1 INTO pat2;
EXECUTE 'INSERT INTO observation (classcode, moodcode, code, confidentialitycode, effectivetime, value)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'',
        ''{n}'', ''[20090227 130000, 20090227 130000]'', 130) RETURNING id' INTO obs1;

/* Just for the sake of testing, let's make the diastolic observation sensitive */
EXECUTE 'INSERT INTO observation (classcode, moodcode, code, confidentialitycode, effectivetime, value)
        VALUES (''obs'', ''evn'', ''271650006|Diastolic blood pressure'',
        ''{s}'', ''[20090227 130000, 20090227 130000]'', 90) RETURNING id' INTO obs2;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''rct'') RETURNING id' USING obs1, pat2;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''rct'') RETURNING id' USING obs2, pat2;

/* John Doe has an appointment with the Community Mental Health Clinic. Since this information concerns
mental health, the fact that he is patient and that he has an appointment at such a clinic is considered
restricted. */
EXECUTE 'INSERT INTO organization (classcode, name, industrycode)
        VALUES (''org'', ''Community Mental Health Clinic'', ''hos'') RETURNING id' INTO org2;
EXECUTE 'INSERT INTO patient (classcode, player, scoper, confidentialitycode)
        VALUES (''pat'', $1, $2, ''{r}'') RETURNING id' USING psn3, org2 INTO pat3;
EXECUTE 'INSERT INTO act (classcode, moodcode, code, confidentialitycode, effectivetime)
        VALUES (''enc'', ''apt'', ''intake'', ''{s, r}'', ''[20140301, 20140301]'') RETURNING id' INTO act2;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''rct'') RETURNING id' USING act2, pat3;

/* The appointment above is with Dr. Sigmund. */
EXECUTE 'INSERT INTO person (classcode, name)
        VALUES (''psn'', ''Dr. Sigmund'') RETURNING id' INTO psn4;
EXECUTE 'INSERT INTO employee (classcode, player, scoper, jobcode, pgname)
        VALUES (''emp'', $1, $2, ''Psychiatrist'',''sigmund'')
        RETURNING id' USING psn4, org2 INTO emp2;
EXECUTE 'INSERT INTO participation (act, role, typecode)
        VALUES ($1, $2, ''prf'') RETURNING id' USING act2, emp2;

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

\echo ======= PARTICIPATION =======
SELECT * FROM participation;


/* Community Health and Hospitals has as policy that when information is
regarded sensitive, it can be accessed only by the treating physicians.

This RLS qual is written in such a way that the subquery is to be pulled up at
execution time. */
ALTER TABLE act SET ROW SECURITY FOR ALL TO (
      EXISTS (
         SELECT 1
         FROM employee emp
         LEFT JOIN participation part ON emp.id = part.role
         WHERE (part.act = act.id AND emp.pgname = current_user)
         OR NOT(act.confidentialitycode @> '{s}')));

/* Since observation is a child of act, we need to duplicate the RLS above for
observation, otherwise access is open through querying observation directly. */
ALTER TABLE observation SET ROW SECURITY FOR ALL TO (
      EXISTS (
         SELECT 1
         FROM employee emp
         LEFT JOIN participation part ON emp.id = part.role
         WHERE (part.act = observation.id AND emp.pgname = current_user)
         OR NOT(observation.confidentialitycode @> '{s}')));

/* For the sake of testing RLS on tables that are used in other table's RLS:
Psychiatrists are not allowed to see any employee records. Other doctors may
see all employees. */

/* The following policy causes problems when accessing the employee table
ERROR: infinite recursion detected for relation 'employee'. This is good
(instead of e.g. infinite regress into a memory error).

ALTER TABLE employee SET ROW SECURITY FOR ALL TO (
      EXISTS (
         SELECT 1
         FROM employee emp
         WHERE (emp.pgname = current_user
         AND emp.jobcode <> 'Psychiatrist')
         OR NOT(employee.jobcode = 'Psychiatrist')));
*/

/* If we change the restrictions it works */
ALTER TABLE employee SET ROW SECURITY FOR ALL TO (
      CASE WHEN current_user = 'sigmund' THEN false
      ELSE (employee.jobcode != 'Psychiatrist') END);


SET SESSION AUTHORIZATION henry;
SELECT * FROM act; -- fails, which is good: RLS does not circumvent the usual
                   -- grant privileges.

SET SESSION AUTHORIZATION default;
GRANT SELECT ON ALL TABLES IN SCHEMA hl7 TO public;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA hl7 TO public;

GRANT INSERT ON ALL TABLES IN SCHEMA hl7 TO public;
GRANT UPDATE ON ALL TABLES IN SCHEMA hl7 TO public;
GRANT DELETE ON ALL TABLES IN SCHEMA hl7 TO public;

SET SESSION AUTHORIZATION henry;
SELECT * FROM act;         -- Ok, shows only non-sensitive rows and rows where
                           -- henry is performer.
EXPLAIN SELECT * FROM act; -- Good, subquery is pulled up.
SELECT * FROM observation; -- Ok, shows only non-sensitive rows and rows where
                           -- henry is performer.

SET SESSION AUTHORIZATION sigmund;
SELECT * FROM act;         -- Ok, shows no information, which is expected since
                           -- to evaluate RLS on act, access to the employee
                           -- table is necessary, which sigmund does not have.
SELECT * FROM observation; -- Same here.

SET SESSION AUTHORIZATION pete;
SELECT * FROM act;         -- Ok, shows only non-sensitive rows.
SELECT * FROM observation;
SELECT * FROM employee;

/*** Pete may insert sensitive data.. */
INSERT INTO observation (classcode, moodcode, code, confidentialitycode, value)
VALUES ('obs', 'evn', 'bell la padula', '{s}', 130);

/* .... even though he cannot read this afterwards */
/* This behaviour is ok for our use cases, but it might be a POLA
violation. After all, the ROW SECURITY was set FOR ALL commands, which includes
insert. */
SELECT * FROM observation WHERE code = 'bell la padula';

/* ... or update */
UPDATE observation SET code = 'new code' WHERE code = 'bell la padula';

/* ... or delete */
DELETE FROM observation WHERE code = 'bell la padula';

/* Everything is well until now. However, what if we want to restrict access to
Patient based on the vipcode?

Knowledge about VIP patients can only be seen by doctors having performed a
healthcare act for that patient. */

SET SESSION AUTHORIZATION default;

ALTER TABLE patient RESET ROW SECURITY FOR ALL;

ALTER TABLE patient SET ROW SECURITY FOR ALL TO (
      EXISTS (
         SELECT 1
         FROM employee emp
         LEFT JOIN participation partemp
         ON emp.id = partemp.role
         AND partemp.typecode='prf'
         LEFT JOIN act
         ON partemp.act = act.id
         LEFT JOIN participation partpat
         ON partpat.role = patient.id
         AND partpat.typecode = 'rct'
         WHERE emp.pgname = current_user
         OR patient.vipcode IS DISTINCT FROM 'vip'));

/* The effect of this rule is that only Henry may see the patient row of
Isabella. */
SET SESSION AUTHORIZATION henry;
SELECT patient.id, vipcode, person.name, birthtime, organization.name
FROM patient, person, organization -- ok, shows only non-sensitive rows and
WHERE patient.player = person.id   -- rows where henry is performer
AND patient.scoper = organization.id;

EXPLAIN SELECT * FROM patient;

SET SESSION AUTHORIZATION sigmund;
SELECT * FROM patient;         -- ok, shows no information, since sigmund may
                               -- not access the employee table
SET SESSION AUTHORIZATION pete;
SELECT patient.id, vipcode, person.name, birthtime, organization.name
FROM patient, person, organization -- ok, shows only the non-vip rows
WHERE patient.player = person.id
AND patient.scoper = organization.id;

/* There is a problem though that pete can still see that Isabella is a
patient through the role table, by accessing the patient info through
'role'. */
SELECT role.id, person.name, birthtime, organization.name
FROM role, person, organization
WHERE role.player = person.id
AND role.scoper = organization.id
AND role.classcode = 'pat';

/* This query will show Isabella Jones, but we have no way to specify row
security on Role to prevent access to Isabella as vip. */

/* The same holds for policies in the Act hierarchy, if they need to restrict
access based on attributes not part of the root table. An example would be to
restrict access on e.g. bloodpressures if the values are unusually high. */

/* Summary: the current RLS patch works on inheritance trees for row
restrictions that can be specified using only the attributes in the inheritance
root relation. Since security labeling in the RIM is done on
confidentialitycodes that are present in the inheritance roots Role and Act,
the current RLS patch for the RIM. The milage may vary for other
non-partitioning use cases of PostgreSQL inheritance. */

/* Views on tables with RLS respect the RLS: good */
SET SESSION AUTHORIZATION default;
CREATE VIEW test AS SELECT * FROM act;
GRANT ALL ON test TO sigmund;
SET SESSION AUTHORIZATION sigmund;
SELECT * FROM test;

\quit

/* Remarks about error messages:

ERROR:  must be owner of relation employee

Is 'relation' the word to use in an error message or 'table'?  It would also be
more informing in the error log if the user was hinted in some way it was ROW
SECURITY that caused the error.

ERROR:  cannot set row security for table 'employee': not owner
or
ERROR:  must be owner of 'employee' to set row security

Dito for this error message
ERROR:  infinite recursion detected for relation 'employee'
what about
ERROR:  infinite recursion in row security for table 'employee'

*/
