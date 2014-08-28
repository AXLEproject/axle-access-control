DROP ROLE IF EXISTS bob;
DROP ROLE IF EXISTS sigmund;
DROP ROLE IF EXISTS ronan;
DROP ROLE IF EXISTS pete;
DROP ROLE IF EXISTS henry;

/* The users that will access the application. */
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

_EXTRAUSECASE_

END;
$$ LANGUAGE plpgsql;
