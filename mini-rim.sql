-- MINI HL7 RIM for purpose of review row level security
-- no healthcare datatypes
-- very limited amount of classes

DROP SCHEMA IF EXISTS minirim CASCADE;


CREATE SCHEMA minirim;
GRANT USAGE ON SCHEMA  minirim TO public;

SET search_path = minirim;

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
CREATE TYPE EntityClass AS ENUM (
       'psn', -- person
       'org' -- organization
);

/* The real NAICS codesystem uses numbers. For this example, mnemonics are used
instead. */ 
CREATE TYPE OrganizationIndustryClass AS ENUM (
       'fam',  -- family planning center
       'hos',  -- hospital
       'psah', -- psychiatric and substance abuse hospitals
       'omhs'  -- offices of mental health specialists
);

CREATE TYPE RoleClass AS ENUM (
       'pat',     -- person
       'emp',     -- employee
       'aen'      -- assigned entity
);
CREATE TYPE PatientImportance AS ENUM (
       'bm',     -- board member
       'vip',    -- very important person
       'for'     -- foreign dignitary
);

CREATE TYPE ActClass AS ENUM (
       'obs',    -- observation
       'sbadm',  -- substance administration
       'pcpr',   -- care provision
       'enc'     -- encounter
);

CREATE TYPE ActMood AS ENUM (
       'def',    -- definition
       'evn',    -- event
       'gol',    -- goal
       'rqo',    -- request or order
       'apt'     -- appointment
);

CREATE TYPE EmployeeJobClass AS ENUM (
       'doc',    -- doctor
       'int',    -- intern doctor
       'nur',    -- nurse
       'res',    -- researcher
       'adm'     -- administration
);

CREATE TYPE ParticipationType AS ENUM (
       'prf',    -- performer
       'rcv',     -- receiver (patient about which the record is about)
       'ent',     -- enterer
       'la'       -- legal authenticator
);

CREATE TYPE Confidentiality AS ENUM (
       'n',    -- normal
       'r',    -- restricted
       'v'     -- very restricted
);


CREATE TABLE Entity (
       _id        int PRIMARY KEY DEFAULT nextval('seq'),
       classCode EntityClass NOT NULL,
       name      text);
CREATE TABLE Person (birthtime timestamp) INHERITS (entity);
CREATE TABLE Organization (standardIndustryClassCode OrganizationIndustryClass) INHERITS (entity);

CREATE TABLE Role (
       _id         int PRIMARY KEY DEFAULT nextval('seq'),
       classCode  roleClass NOT NULL,
       _player     int NOT NULL, -- references entity(id)
       _scoper     int,          -- references entity(id)
       effectiveTime tsrange,
       confidentialityCode Confidentiality
       );
-- why double id 
CREATE TABLE Patient (_id int PRIMARY KEY, veryImportantPersonCode PatientImportance) INHERITS (Role);
CREATE TABLE Employee (jobCode EmployeeJobClass, pgname text) INHERITS (role);
CREATE TABLE AssignedEntity () INHERITS (Employee);

CREATE TABLE Act (
       _id                  int PRIMARY KEY DEFAULT nextval('seq'),
       classCode           ActClass NOT NULL,
       moodCode            ActMood NOT NULL,
       code                text,
       effectiveTime       tsrange,
       confidentialityCode Confidentiality,
       _clinical_segment    text[]
       );

CREATE TABLE CareProvision () INHERITS (Act); -- used for stating that a patient is under care provision
CREATE TABLE Observation (value text) INHERITS (Act);
CREATE TABLE SubstanceAdministration (doseQuantity numeric) INHERITS (Act);

CREATE TABLE Participation (
       _id       int PRIMARY KEY DEFAULT nextval('seq'),
       _act      int, -- references act(id)
       _role     int, -- references role(id)
       typeCode participationType,
       effectiveTime       tsrange
       );