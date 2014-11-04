-- Copyright (c) 2014, Portavita BV Netherlands

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
SELECT * FROM CareProvision;

\echo ======= PARTICIPATION =======
SELECT * FROM participation;
