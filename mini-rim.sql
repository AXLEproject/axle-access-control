-- Copyright (c) 2013, Portavita BV Netherlands
--
-- MINI HL7 RIM for purpose of review row level security --
-- no healthcare datatypes
-- very limited amount of classes
SET SESSION AUTHORIZATION default;
DROP SCHEMA IF EXISTS minirim CASCADE;

CREATE SCHEMA minirim;
GRANT USAGE ON SCHEMA  minirim TO public;

SET search_path = minirim;
ALTER DATABASE _DB_ SET SEARCH_PATH = minirim;

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

-- http://www.hl7.org/documentcenter/public_temp_E5E731D0-1C23-BA17-0CD938440CF24081/standards/vocabulary/vocabulary_tables/infrastructure/vocabulary/vs_RoleClass.html#RoleClassRoot
CREATE TYPE RoleClass AS ENUM (
       'pat',          -- person
       'emp',          -- employee 
       'assigned',     -- assigned entity
       'prov',         -- healthcare provider (doctor?)
       'nurs',         -- nurse
       'phys'          -- physician

);

-- codesys: HL7v3RoleCode, Oid: 2.16.840.1.113883.5.111 (basically specialization of roleclass, Code Set: Healthcare Provider Role Type )
CREATE TYPE RoleCode AS ENUM ( 
       'md',     -- medical doctor
       'rn'     -- registered nurse
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
       'enc',    -- encounter
       'cons',    -- consent
       'act'
);

CREATE TYPE ActMood AS ENUM (
       'def',    -- definition
       'evn',    -- event
       'gol',    -- goal 
       'rqo',    -- request or order
       'apt'     -- appointment
);


-- EmployeeJobClass  [2.16.840.1.113883.5.1059]
CREATE TYPE EmployeeJobClass AS ENUM ( 
       'ft',     -- Full-time
       'pt'      -- part-time
);

CREATE TYPE ParticipationType AS ENUM (
       'prf',    -- performer
       'rcv',    -- receiver (patient about which the record is about)
       'ent',    -- enterer
       'la',     -- legal authenticator
       'cst',    -- custodian (Entity in charge of maintaining the information of this act)
       'aut',    -- One who initiates the control act event, either as its author or its physical performer.
       'rct',     -- record target
       'ircp',    -- information recipient
       'atnd'     -- The practitioner that has responsibility for overseeing a patient's care during a patient encounter. (participation as assigned entity)

);

CREATE TYPE Confidentiality AS ENUM (
       'n',    -- normal
       'r',    -- restricted
       'v'     -- very restricted
);

CREATE TYPE ActRelationshipType AS ENUM (
      'comp', -- component
      'auth', -- authorize
      'apnd'  -- append
);

CREATE TYPE ActStatus AS ENUM (
       'active',     
       'completed',  
       'new',     
       'cancelled',
       'aborted',
       'suspended',
       'held'
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
       code        text,      
       _player     int , -- references entity(id) XXX can be null (according to hl7) in order to express the generic role of researcher!!
       _scoper     int,          -- references entity(id) XXX can be null 
       effectiveTime tsrange,
       confidentialityCode Confidentiality,
       _pgname     text
       );
-- why double id 
CREATE TABLE Patient (_id int PRIMARY KEY, veryImportantPersonCode PatientImportance) INHERITS (Role);
CREATE TABLE Employee () INHERITS (Role); -- classcode will be 'emp', code will be 'ft' or 'pt'
CREATE TABLE AssignedEntity () INHERITS (Role); -- classcode will be 'assigned', code will be medical doctor 'md' or registered nurse 'rn' 

CREATE TABLE Act (
       _id                  int PRIMARY KEY DEFAULT nextval('seq'),
       classCode           ActClass NOT NULL,
       moodCode            ActMood NOT NULL,
       code                text,
       effectiveTime       tsrange,
       confidentialityCode Confidentiality,
       statusCode          ActStatus,
       negationInd         boolean,
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

CREATE TABLE ActRelationship (
       _id                  int PRIMARY KEY DEFAULT nextval('seq'),
       _act_source          int NOT NULL,
       _act_target          int NOT NULL,
       typeCode             ActRelationshipType
       );
