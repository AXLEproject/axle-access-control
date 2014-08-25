
DROP ROLE IF EXISTS bob;
DROP ROLE IF EXISTS sigmund;
DROP ROLE IF EXISTS ronan;
DROP ROLE IF EXISTS pete;
DROP ROLE IF EXISTS henry;

/* The users that will access the application */
CREATE ROLE ronan;
CREATE ROLE bob;
CREATE ROLE sigmund;
CREATE ROLE pete;
CREATE ROLE henry;

CREATE TABLE ObservationAction () INHERITS (Observation);
CREATE TABLE ObservationRelatedProblem () INHERITS (Observation);
CREATE TABLE ActConsent() INHERITS (Act);
CREATE TABLE ConsentDirective() INHERITS (Act);

-- CREATE TABLE Consent (
--        patientId             int REFERENCES Patient(_id),
--        roleId                int REFERENCES Role(_id),
--        org                   int REFERENCES Organization(_id),
--        role_class            RoleClass, -- e.g. assigned entity
--        role_code             text, -- e.g. atnd (attending physician), rn (registered nurse)
--        action                text, -- read/write
--        purposeOfUse          text, -- Treatment, Research 
--        informationReference  text -- Clinical Segment
-- );
-- CREATE TABLE Consent (
--        roleId                int REFERENCES Patient(_id),
--        action                text,
--        purposeOfUse          text,
--        informationReference  text
-- );

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
emp_res     int;
emp_ronan   int;
aen_ronan   int;
emp_pete    int;
emp_henry   int;
aen_henry   int;
aen_pete    int;
act1        int;
act2        int;
org1        int;
org2        int;
obs1        int;
obs2        int;
act_consent int;
act_consent_dir_1 int;
act_consent_dir_2 int;
act_consent_dir_3 int;
obs_rel_problem int;
obs_action  int;

BEGIN
/* Mary White has been diagnosed diabetes type 1 and starts getting treated at Community Health and Hospitals.
*/
EXECUTE 'INSERT INTO Person (classCode, name, birthtime)
        VALUES (''psn'', ''Mary White'', ''19500221'') RETURNING _id' INTO mary;

EXECUTE 'INSERT INTO Organization (classCode, name, standardIndustryclassCode)
        VALUES (''org'', ''Community Health and Hospitals'', ''hos'') RETURNING _id' INTO org1;

-- NB: The patient personal data has no particular access restriction ('n')
EXECUTE 'INSERT INTO Patient (classCode, _player, _scoper, effectiveTime, confidentialityCode, veryImportantPersonCode)
        VALUES (''pat'', $1, $2, ''[20120908,]'', ''n'', NULL) RETURNING _id' USING mary, org1 INTO pat_mary; 

-- The following is to indicate that Mary is being treated for diabetes. NB: All health records are confidential, so access is restricted 'r'
EXECUTE 'INSERT INTO CareProvision (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment)
        VALUES (''pcpr'', ''evn'', ''73211009|Diabetes mellitus'', ''[20120908,]'', ''r'', ''active'', ''{diabetes}'') RETURNING _id' INTO act1;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rcv'', ''[20120908,infinity)'') RETURNING _id' USING act1, pat_mary;

/* Dr Pete is a physician */
EXECUTE  'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Pete Rain'') RETURNING _id' INTO pete;

/* He is employeed at the Health and Community Hospitals */
EXECUTE 'INSERT INTO Employee (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''emp'', ''ft'', $1, $2, ''[20090227,]'', ''n'', ''pete'')
        RETURNING _id' USING pete, org1 INTO emp_pete;

/* Dr. Pete is the treating physician of Mary White. NB: A nurse can also be an assigned entity. Pay attention at the classcode and the code (md=medical doctor).  */
EXECUTE 'INSERT INTO AssignedEntity (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''assigned'', ''md'', $1, $2, ''[20131108,]'', ''n'', ''pete'')
        RETURNING _id' USING pete, org1 INTO aen_pete;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''atnd'',''[20120909,infinity)'')' USING act1, aen_pete;

/* Add a blood pressure measurement to the diabetes treatment */
EXECUTE 'INSERT INTO Observation (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment,  value)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'', ''[20090227 130000, 20090227 130000]'', ''r'', ''completed'', ''{diabetes}'', 130) RETURNING _id' INTO obs1;
/* Dr. Pete performed this observation */
EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''prf'',''[20120909,infinity)'')' USING obs1, aen_pete;



/*------- ORGANIZATIONAL POLICIES ----------- */
/* Isabella Jones is a celebrity and patient at Community Health and Hospitals.
 */
EXECUTE 'INSERT INTO Person (classCode, name, birthtime)
        VALUES (''psn'', ''Isabella Jones'', ''19750501'') RETURNING _id' INTO isabella;

EXECUTE 'INSERT INTO Patient (classCode, _player, _scoper, effectiveTime,  confidentialityCode, veryImportantPersonCode)
        VALUES (''pat'', $1, $2, ''[20120908,infinity)'', ''v'', ''vip'')
        RETURNING _id' USING isabella, org1 INTO pat_isabella;

/* Isabella Jones is being treated for her diabetes problem. Since she is a celebrity all
information concerning this treatment is classified as very restricted. */
EXECUTE 'INSERT INTO CareProvision (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment)
        VALUES (''pcpr'', ''evn'',''73211009|Diabetes mellitus'', ''[20120908,infinity)'', ''v'', ''active'', ''{diabetes}'')
        RETURNING _id' INTO act2;

EXECUTE 'INSERT INTO Participation (_act, _role, typecode, effectiveTime) 
         VALUES ($1, $2, ''rcv'',''[20120908,infinity)'')' USING act2, pat_isabella;

/* Dr. Henry Seven, working at Community Health and Hospitals, is the primary care provider of Mrs. Jones for the diabetes treatment.
*/
EXECUTE 'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Henry Seven'') RETURNING _id' INTO henry;

EXECUTE 'INSERT INTO Employee (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''emp'', ''ft'', $1, $2, ''[20120908,infinity)'', ''n'', ''henry'')
        RETURNING _id' USING henry, org1 INTO emp_henry;

EXECUTE 'INSERT INTO AssignedEntity (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''assigned'', ''md'', $1, $2, ''[20120908,infinity)'', ''n'', ''henry'')
        RETURNING _id' USING henry, org1 INTO aen_henry;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''atnd'',''[20120908,infinity)'') '
        USING act2, aen_henry;


/* In the context of her diabetes treatment, Isabella Jones has her blood pressure measured by Dr. Henry. The observation is very restricted because Isabella Jones is a VIP. */
EXECUTE 'INSERT INTO Observation (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, value, _clinical_segment)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'', ''[20120908, 20120908]'', ''v'', ''completed'', 140, ''{diabetes}'') 
        RETURNING _id' INTO obs2;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rcv'',''[20120908, 20120908]'') 
        RETURNING _id' USING obs2, pat_isabella;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''prf'',''[20120908, 20120908]'')
        RETURNING _id' USING obs2, aen_henry;


-- Ronan Blue is a doctor in Community Health Hospital
EXECUTE  'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Ronan Blue'') RETURNING _id' INTO ronan;

EXECUTE 'INSERT INTO Employee (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''emp'', ''ft'', $1, $2, ''[20100227,]'', ''n'', ''ronan'')
        RETURNING _id' USING ronan, org1 INTO emp_ronan;

EXECUTE 'INSERT INTO AssignedEntity (classCode,  code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''assigned'', ''md'', $1, $2, ''[20100227,]'', ''n'', ''ronan'')
        RETURNING _id' USING ronan, org1 INTO aen_ronan;

END;
$$ LANGUAGE plpgsql;

/* Superuser can select all */

\echo ====== ENTITY HIERARCHY ========
SELECT * FROM Entity;

\echo ORGANIZATION
SELECT * FROM Organization;

\echo PERSON
SELECT * FROM Person;

\echo ======= ROLE HIERARCHY ========
SELECT * FROM Role;

\echo PATIENT
SELECT * FROM Patient;

\echo EMPLOYEE
SELECT * FROM Employee;

\echo ======= ACT HIERARCHY ========
SELECT * FROM Act;

\echo OBSERVATION
SELECT * FROM Observation;

\echo CareProvision
SELECT * FROM CareProvision;

\echo ACT CONSENT
SELECT * FROM ActConsent;

\echo CONSENT DIRECTIVE
SELECT * FROM ConsentDirective;

\echo ======= PARTICIPATION =======
SELECT * FROM Participation;

\echo ======= ACT RELATIONSHIPS =======
SELECT * FROM ActRelationship;


-- RLS --
SET SESSION AUTHORIZATION default;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA minirim TO public;
GRANT ALL ON ALL TABLES IN SCHEMA minirim TO public;
-- GRANT INSERT ON ALL TABLES IN SCHEMA minirim TO public;
-- GRANT UPDATE ON ALL TABLES IN SCHEMA minirim TO public;
-- GRANT DELETE ON ALL TABLES IN SCHEMA minirim TO public;

-- OLD VERSION -- ignore
-- Only the treating physician can see 'v' records.  
-- ALTER TABLE Act SET ROW SECURITY FOR ALL TO (
--     EXISTS (
--         SELECT 1 FROM Patient pat1 
--         LEFT JOIN Participation part1 on pat1._id=part1._role 
--         LEFT JOIN CareProvision cp ON cp._id=part1._act

--         LEFT JOIN Participation part2 on part2._act=cp._id
--         LEFT JOIN AssignedEntity assent on assent._id=part2._role

--         LEFT JOIN Participation part3 on part3._act=act._id
--         LEFT JOIN Patient pat2 on pat2._id=part3._role

--         where cp._clinical_segment=act._clinical_segment
--         AND pat1._id=pat2._id
--         AND assent._pgname=current_user )

--     OR act.confidentialityCode != 'v' -- func(act.confidentialityCode) <= func(select jobcode from employee emp where emp.pgname=current_user) ) 
--     );


-- Only the treating physicians can see 'v' records.  
ALTER TABLE Act SET ROW SECURITY FOR ALL TO (
    CASE WHEN act.confidentialityCode = 'v' 
        THEN ( 
            EXISTS (
            SELECT 1 FROM Patient pat1 
            LEFT JOIN Participation part1 on pat1._id=part1._role 
            LEFT JOIN CareProvision cp ON cp._id=part1._act

            LEFT JOIN Participation part2 on part2._act=cp._id
            LEFT JOIN AssignedEntity assent on assent._id=part2._role

            LEFT JOIN Participation part3 on part3._act=act._id
            LEFT JOIN Patient pat2 on pat2._id=part3._role

            where cp._clinical_segment=act._clinical_segment
            AND pat1._id=pat2._id
            AND now() < upper(part2.effectiveTime) 
            AND assent._pgname=current_user )
        ) 
        WHEN act.confidentialityCode='r' THEN (
            EXISTS (
                SELECT 1 FROM AssignedEntity assent
                WHERE assent._pgname=current_user 
                AND assent.code='md')
            )
        ELSE  true END);

-- We apply the same rule to the Observation table
ALTER TABLE Observation SET ROW SECURITY FOR ALL TO (
        CASE WHEN observation.confidentialityCode = 'v' 
            THEN ( 
                EXISTS (
                SELECT 1 FROM Patient pat1 
                LEFT JOIN Participation part1 on pat1._id=part1._role 
                LEFT JOIN CareProvision cp ON cp._id=part1._act

                LEFT JOIN Participation part2 on part2._act=cp._id
                LEFT JOIN AssignedEntity assent on assent._id=part2._role

                LEFT JOIN Participation part3 on part3._act=observation._id
                LEFT JOIN Patient pat2 on pat2._id=part3._role

                where cp._clinical_segment=observation._clinical_segment
                AND pat1._id=pat2._id
                AND now() < upper(part2.effectiveTime) 
                AND assent._pgname=current_user )
        ) 
        WHEN observation.confidentialityCode='r' THEN (
            EXISTS (
                SELECT 1 FROM AssignedEntity assent
                WHERE assent._pgname=current_user 
                AND assent.code='md')
            )
        ELSE  true END);

-- Same to the CareProvision table [ and to any other table deriving from Acts ]
ALTER TABLE CareProvision SET ROW SECURITY FOR ALL TO (
    CASE WHEN careprovision.confidentialityCode = 'v' THEN ( 
            EXISTS (
                SELECT 1 FROM AssignedEntity assent 
                LEFT JOIN Participation part ON part._role=assent._id 
                WHERE part._act=CareProvision._id AND assent._pgname=current_user )
            ) 
        WHEN careprovision.confidentialityCode='r' THEN (
            EXISTS (
                SELECT 1 FROM AssignedEntity assent
                WHERE assent._pgname=current_user 
                AND assent.code='md')
            )
        ELSE  true END);


-- The same rule is valid for the personal data. Only treating physicians can see personal data of VIP patients
ALTER TABLE Patient SET ROW SECURITY FOR ALL TO (
    CASE WHEN patient.confidentialityCode = 'v' THEN ( 
            EXISTS (
                SELECT 1 FROM AssignedEntity assent 
                LEFT JOIN Participation part on part._role=assent._id
                LEFT JOIN CareProvision cp ON cp._id=part._act

                LEFT JOIN Participation part2 on part2._act=cp._id
                WHERE patient._id=part2._role
                AND assent._pgname=current_user)
            )
        WHEN patient.confidentialityCode='r' THEN (
            EXISTS ( 
                SELECT 1 FROM AssignedEntity assent
                WHERE assent._pgname=current_user 
                AND assent.code='md' )
            )
        ELSE true END);

-- TODO: same also for the Person table -- probably..
-- ALTER TABLE Person SET ROW SECURITY FOR ALL TO (
--     EXISTS (
--         SELECT 1 FROM Patient pat
--         LEFT JOIN Participation part1 ON part1._role=pat._id
--         LEFT JOIN CareProvision cp ON cp._id=part1._act

--         LEFT JOIN Participation part2 on part2._act=cp._id
--         LEFT JOIN AssignedEntity assent on assent._id=part2._role
--         WHERE person._id=pat._player
--         AND assent._pgname=current_user )
--     OR  EXISTS (
--         SELECT 1 FROM Patient pat2 -- NB referred to patients!
--         WHERE person._id=pat2._player and pat2.confidentialityCode != 'v')
--     );


-- Henry cannot access any records any more.. THis policy overrides the access rights of the other rules. Ronan cannot either if the other rules above are executed. Seems that rules exclude each other. Should be accumulated evaluation instead of mutual exclusion.

-- ALTER TABLE Act SET ROW SECURITY FOR ALL TO ( 
--     EXISTS (
--         SELECT 1 FROM Person pers 
--         LEFT JOIN Patient pat ON pat._player=pers._id
--         LEFT JOIN Participation part ON pat._id=part._role 
--         WHERE  act._id=part._act 
--         AND pers.name='Isabella Jones')
--     AND EXISTS (
--         SELECT 1 FROM Organization org2
--         LEFT JOIN AssignedEntity assent on assent._scoper=org2._id
--         WHERE org2.name='XRay Lab'
--         AND assent.classCode='assigned'
--         AND assent._pgname=current_user
--         AND now() < date '09-01-2014'
--         )
--     );


\echo == User is henry. He can access all the records. ==
\echo == ACTS
SET SESSION AUTHORIZATION henry;
SELECT * FROM Act;

\echo == User is pete. He can access only 'r' records. ==
\echo == ACTS
SET SESSION AUTHORIZATION pete;
SELECT * FROM Act;

\echo == Doctor Henry is not any more the treating physician of Isabella Jones. 
-- Terminate participation of doctor Henry in the treatment of Isabella. Set an end to the effective time of the participation
-- Have to do it as superuser
SET SESSION AUTHORIZATION default;
UPDATE Participation SET effectiveTime=tsrange(lower(participation.effectiveTime),'20140404', '[]')
    FROM      CareProvision cp
    LEFT JOIN Participation part2 ON part2._act=cp._id
    LEFT JOIN Patient pat ON part2._role=pat._id
    LEFT JOIN Person pers ON pat._player=pers._id
    WHERE participation._act=cp._id 
    AND participation.typecode = 'atnd' 
    AND part2.typeCode='rcv' 
    AND  pers.name='Isabella Jones'
    AND '{diabetes}' <@ cp._clinical_segment;

\echo == Trying to access acts as Henry. Should not see any more records of Isabella.
\echo == ACTS
SET SESSION AUTHORIZATION henry;
SELECT * FROM Act;

\echo == Dr. Pete is now the treating physician of Isabella Jones.
-- Back to superuser to change participation
SET SESSION AUTHORIZATION default;

-- Pete is now the primary physician of Isabella Jones. A new participation from Pete to the  diabetes CareProvision of Isabella.
INSERT INTO Participation (_act, _role, typeCode, effectiveTime) VALUES 
    ( 
      (SELECT cp._id FROM CareProvision cp
        LEFT JOIN Participation part ON part._act=cp._id
        LEFT JOIN Patient pat ON part._role=pat._id
        LEFT JOIN Person pers ON pat._player=pers._id  
        WHERE  pers.name='Isabella Jones'
        AND '{diabetes}' <@ cp._clinical_segment),
      (SELECT assent._id FROM AssignedEntity assent
        WHERE  assent._pgname = 'pete'),
        'atnd',
        '[20140814,infinity)');

\echo == Accessing acts as Pete.
\echo == ACTS 
SET SESSION AUTHORIZATION pete;
SELECT * FROM Act;



-- Question: what if we want to add another rule on the table Acts? For example, Doctor Ronan, although is not the treating physician of Isabella Jones, he is allowed to see her records. We should see something like this:
SET SESSION AUTHORIZATION default;


ALTER TABLE Act SET ROW SECURITY FOR ALL TO ( 
    EXISTS (
        SELECT 1 FROM Person pers 
        LEFT JOIN Patient pat ON pat._player=pers._id
        LEFT JOIN Participation part ON pat._id=part._role 
        WHERE  act._id=part._act 
        AND pers.name='Isabella Jones'
        AND current_user='ronan'
        )
    );

\echo == Ronan trying accessing Act: sees nothing
SET SESSION AUTHORIZATION ronan;
SELECT * FROM Act;

\echo == Pete trying to access Act: sees nothing
SET SESSION AUTHORIZATION pete;
SELECT * FROM Act;

\echo == Resetting all the rules. And applying now only the rule with Ronan

SET SESSION AUTHORIZATION default;
ALTER TABLE Act RESET ROW SECURITY FOR ALL;  
ALTER TABLE Patient RESET ROW SECURITY FOR ALL;  

ALTER TABLE Act SET ROW SECURITY FOR ALL TO ( 
    EXISTS (
        SELECT 1 FROM Person pers 
        LEFT JOIN Patient pat ON pat._player=pers._id
        LEFT JOIN Participation part ON pat._id=part._role 
        WHERE  act._id=part._act 
        AND pers.name='Isabella Jones'
        AND current_user='ronan'
        )
    );

\echo == Ronan trying to see Act table: manages to see the acts of Isabella only
SET SESSION AUTHORIZATION ronan;
SELECT * FROM Act;  

-- Conclusion: we should collect all rules concerning a given table into one RLS statement. 



