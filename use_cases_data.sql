-- Copyright (c) 2014, Portavita BV Netherlands


/* Auxilary table for recording patient opt outs */
CREATE TABLE OptOutConsent(
    _id        int PRIMARY KEY DEFAULT nextval('seq'),
	organizationId 	int,
	patientId	int,
	careProvision	text
);

DO $$
DECLARE
mary        int;
isabella    int;
pete        int;
ronan       int;
pat_mary    int;
pat_isabella int;
emp_ronan   int;
aen_ronan   int;
emp_pete    int;
aen_pete    int;
act1        int;
act2        int;
act3        int;
org1        int;
obs1        int;
obs2        int;
obs_rel_problem int;
obs_action  int;

BEGIN
/* Mary White has been diagnosed diabetes type 1 and starts getting treated at Community Health and Hospitals.
*/
EXECUTE 'INSERT INTO Person (classCode, name, birthtime)
        VALUES (''psn'', ''Mary White'', ''19500221'') RETURNING _id' INTO mary;

EXECUTE 'INSERT INTO Organization (classCode, name, standardIndustryclassCode)
        VALUES (''org'', ''Community Health and Hospitals'', ''hos'') RETURNING _id' INTO org1;

EXECUTE 'INSERT INTO Patient (classCode, _player, _scoper, effectiveTime, confidentialityCode)
        VALUES (''pat'', $1, $2, ''[20120908,infinity)'', ''n'') RETURNING _id' USING mary, org1 INTO pat_mary; 

/* Table CareProvision keeps record of treatment care. The status field indicates whether the treatment is active to a patient.  */
EXECUTE 'INSERT INTO CareProvision (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode)
        VALUES (''pcpr'', ''evn'', ''73211009'', ''[20120908,infinity)'', ''r'', ''active'') RETURNING _id' INTO act1;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rcv'', ''[20120908,infinity)'') RETURNING _id' USING act1, pat_mary;

/* Dr. Pete Zuckerman is a physician. */
EXECUTE  'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Pete Zuckerman'') RETURNING _id' INTO pete;

/* He is employeed full-time at the Health and Community Hospitals. */
EXECUTE 'INSERT INTO Employee (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''emp'', ''ft'', $1, $2, ''[20090227,infinity)'', ''n'', ''pete'')
        RETURNING _id' USING pete, org1 INTO emp_pete;

/* Dr. Pete is the treating physician of Mary White.  */
EXECUTE 'INSERT INTO AssignedEntity (classCode, code, _player, _scoper, effectiveTime, confidentialityCode)
        VALUES (''assigned'', ''md'', $1, $2, ''[20131108,infinity)'', ''n'')
        RETURNING _id' USING pete, org1 INTO aen_pete; 

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''atnd'',''[20120909,infinity)'')' USING act1, aen_pete;

/* Mary White has her blood pressure measured in the context of the diabetes treatment. */
EXECUTE 'INSERT INTO Observation (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, value)
        VALUES (''obs'', ''evn'', ''271649006|Systolic blood pressure'', ''[20090227 130000, 20090227 130000]'', ''r'', ''completed'', 130) 
        RETURNING _id' INTO obs1;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rcv'',''[20120909,20120909]'')' USING obs1, pat_mary;
        
EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
        VALUES ($1, $2, ''comp'')' USING obs1, act1;

/* Dr. Pete performed this observation */
EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''prf'',''[20120909,20120909]'')' USING obs1, aen_pete;

/* Mary White releases an opt-out consent for records stored in the context of the diabetes treatment */
EXECUTE 'INSERT INTO OptOutConsent (organizationId, patientId, careProvision)
	 VALUES ($1, $2, ''73211009'')' USING org1, pat_mary;

------------------------------------------------
/* Dr Ronan is a physician */
EXECUTE  'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Ronan Lang'') RETURNING _id' INTO ronan;

/* He is employeed at the Health and Community Hospitals */
EXECUTE 'INSERT INTO Employee (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''emp'', ''ft'', $1, $2, ''[20090227,infinity)'', ''n'', ''ronan'')
        RETURNING _id' USING ronan, org1 INTO emp_ronan;

EXECUTE 'INSERT INTO AssignedEntity (classCode, code, _player, _scoper, effectiveTime, confidentialityCode, _pgname)
        VALUES (''assigned'', ''md'', $1, $2, ''[20131108,infinity)'', ''n'', ''ronan'')
        RETURNING _id' USING ronan, org1 INTO aen_ronan;

/* Mary is being treated for COPD by Dr. Ronan.*/
EXECUTE 'INSERT INTO CareProvision (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment)
        VALUES (''pcpr'', ''evn'', ''COPD'', ''[20120908,infinity)'', ''r'', ''active'', ''{diabetes}'') RETURNING _id' INTO act2;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rcv'', ''[20120908,infinity)'') RETURNING _id' USING act2, pat_mary;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''atnd'',''[20120909,infinity)'')' USING act2, aen_ronan;

--------------------------------------------------

/* Isabella Jones is a celebrity and patient at Community Health and Hospitals.
 */
EXECUTE 'INSERT INTO Person (classCode, name, birthtime)
        VALUES (''psn'', ''Isabella Jones'', ''19750501'') RETURNING _id' INTO isabella;

EXECUTE 'INSERT INTO Patient (classCode, _player, _scoper, effectiveTime,  confidentialityCode, veryImportantPersonCode)
        VALUES (''pat'', $1, $2, ''[20120908,infinity)'', ''v'', ''vip'')
        RETURNING _id' USING isabella, org1 INTO pat_isabella;

/* Isabella Jones is being treated for her diabetes problem. */
EXECUTE 'INSERT INTO CareProvision (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment)
        VALUES (''pcpr'', ''evn'',''73211009'', ''[20120908,infinity)'', ''v'', ''active'', ''{diabetes}'')
        RETURNING _id' INTO act3;

EXECUTE 'INSERT INTO Participation (_act, _role, typecode, effectiveTime) 
         VALUES ($1, $2, ''rcv'',''[20120908,infinity)'')' USING act3, pat_isabella;

EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''atnd'',''[20120908,infinity)'') '
        USING act3, aen_pete;



_EXTRAUSECASE_

END;
$$ LANGUAGE plpgsql;
