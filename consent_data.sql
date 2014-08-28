-------------------->>> PATIENT CONSENT 
/* Mary White releases a consent through Dr. Pete.  (NB: code refers to 'Privacy Policy Acknoledgement Document' in LOINC) */
EXECUTE 'INSERT INTO ActConsent (classcode, moodcode, code, effectiveTime, confidentialityCode, statusCode, _clinical_segment) VALUES (''cons'', ''evn'', ''57016-8 '', ''[20120909,20120909]'', ''r'', ''completed'', ''{diabetes}'') RETURNING _id' INTO act_consent;

-- patient who gives consent (record target)
EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''rct'', ''[20120909,20120909]'')' USING act_consent, pat_mary;

-- the custodian
EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''cst'', ''[20120909,20120909]'')' USING act_consent, org1;

-- the author 
EXECUTE 'INSERT INTO Participation (_act, _role, typeCode, effectiveTime)
        VALUES ($1, $2, ''aut'', ''[20120909,20120909]'')' USING act_consent, emp_pete;

-- Consent 1: Allow info disclosure for treatment to Dr Pete

-- the definition of the structured consent, pou: treatment
-- NB must have the statusCode=active
-- code in (HRESCH-health research, TREAT-treatment)
EXECUTE 'INSERT INTO ConsentDirective (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode) VALUES (''act'', ''def'', ''TREAT'', ''[20120909,]'', ''r'',''active'') RETURNING _id' INTO act_consent_dir_1;

-- the person who is the receipient of the consent (in this case the attending physician)
EXECUTE 'INSERT INTO Participation (_act, _role, typecode, effectiveTime)
        VALUES ($1, $2, ''ircp'',  ''[20120909,20120909]'')' USING act_consent_dir_1, aen_pete;

-- the action. code in (IDISCL-information disclosure, RESEARCH-Access for research purposes, RSDID-access for research purposes only in de-identified (and no re-identifiable) form )
EXECUTE 'INSERT INTO ObservationAction (classCode, moodCode, code, effectiveTime, confidentialityCode, negationInd) VALUES (''obs'', ''def'', ''IDISCL'',  ''[20120909,20130909]'', ''r'', ''false'') RETURNING _id' INTO obs_action;

-- the related problem
EXECUTE 'INSERT INTO ObservationRelatedProblem (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode, value) VALUES (''obs'', ''def'', ''8319008|PrincipalDiagnosis'', ''[20120909,20120909]'', ''r'', NULL, ''Portavita174'') RETURNING _id' INTO obs_rel_problem;


EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_1, obs_action;

EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_1, obs_rel_problem;
         
EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent, act_consent_dir_1;



-- EXECUTE 'INSERT INTO Consent (patientId, roleId, org, disclosureType, purposeOfUse, informationReference) VALUES ($1, $2, $3,''IDISCL'', ''TREAT'', ''diabetes'') RETURNING _id' USING pat_mary, aen_pete,  org1 INTO cons;


-- Consent 2: No discolsure to Dr. Bob
/* Mary has had an affair with Doctor Bob Smith, who also works in this hospital. She wants to prevent him from seeing her records concerning the diabetes treatment.
*/
EXECUTE 'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Bob Smith'') RETURNING _id' INTO bob;
EXECUTE 'INSERT INTO Employee (classCode, _player, _scoper, effectiveTime, confidentialityCode, jobCode, pgname)
        VALUES (''emp'', $1, $2, ''[20120908,]'',''n'', ''doc'', ''bob'')
        RETURNING _id' USING bob, org1 INTO emp_bob;
-- the definition of the structured consent, pou: treatment
-- NB must have the statusCode=active
-- code in (HRESCH-health research, TREAT-treatment)
EXECUTE 'INSERT INTO ConsentDirective (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode) VALUES (''act'', ''def'', ''TREAT'', ''[20120909,]'', ''r'',''active'') RETURNING _id' INTO act_consent_dir_2;

-- the person who is the receipient of the consent (in this case the attending physician)
EXECUTE 'INSERT INTO Participation (_act, _role, typecode, effectiveTime)
        VALUES ($1, $2, ''ircp'',  ''[20120909,20120909]'')' USING act_consent_dir_2, emp_bob;

-- the action. code in (IDISCL-information disclosure, RESEARCH-Access for research purposes, RSDID-access for research purposes only in de-identified (and no re-identifiable) form )
EXECUTE 'INSERT INTO ObservationAction (classCode, moodCode, code, effectiveTime, confidentialityCode, negationInd) VALUES (''obs'', ''def'', ''IDISCL'',  ''[20120909,20120909]'', ''r'', ''true'') RETURNING _id' INTO obs_action;

-- the related problem: TODO: How do you protect personal data? Can they be expressed in this block?
EXECUTE 'INSERT INTO ObservationRelatedProblem (classCode, moodCode, code, effectiveTime, confidentialityCode, value) VALUES (''obs'', ''def'', ''8319008|PrincipalDiagnosis'', ''[20120909,20120909]'', ''r'', ''Portavita174'') RETURNING _id' INTO obs_rel_problem;

EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_2, obs_action;

EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_2, obs_rel_problem;
         
EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent, act_consent_dir_2;


-- Consent 3: Allow health research on de-identified data.
/* RLS: Mary White opts in to allow her data concerning diabetes to be used for research. Doctor Ronan Blue, in addition to treating patients, also performs research */
EXECUTE 'INSERT INTO ConsentDirective (classCode, moodCode, code, effectiveTime, confidentialityCode, statusCode) VALUES (''act'', ''def'', ''HRESCH'', ''[20120909,]'', ''r'',''active'') RETURNING _id' INTO act_consent_dir_3;

-- the person who is the receipient of the consent (in this case: someone with researcher capabilities)
/* To this end, we first introduce the generic role of researcher employeed at the Health and Community Hospitals */
EXECUTE 'INSERT INTO Employee (classCode, _player, _scoper, effectiveTime, confidentialityCode, jobCode, pgname)
        VALUES (''emp'', NULL, $1, ''[20090227,]'', ''n'', ''res'',''researcher'')
        RETURNING _id' USING org1 INTO emp_res;

EXECUTE 'INSERT INTO Participation (_act, _role, typecode, effectiveTime)
        VALUES ($1, $2, ''ircp'',  ''[20120909,20120909]'')' USING act_consent_dir_3, emp_res;

-- the action. code in (IDISCL-information disclosure, RESEARCH-Access for research purposes, RSDID-access for research purposes only in de-identified (and no re-identifiable) form )
EXECUTE 'INSERT INTO ObservationAction (classCode, moodCode, code, effectiveTime, confidentialityCode, negationInd) VALUES (''obs'', ''def'', ''RSDID'',  ''[20120909,20120909]'', ''r'', ''false'') RETURNING _id' INTO obs_action;

-- the related problem: TODO: How do you protect *personal data*? Can they be expressed in this block?
EXECUTE 'INSERT INTO ObservationRelatedProblem (classCode, moodCode, code, effectiveTime, confidentialityCode, value) VALUES (''obs'', ''def'', ''8319008|PrincipalDiagnosis'', ''[20120909,20120909]'', ''r'', ''Portavita174'') RETURNING _id' INTO obs_rel_problem;

EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_3, obs_action;

EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent_dir_3, obs_rel_problem;
         
EXECUTE 'INSERT INTO ActRelationship (_act_source, _act_target, typeCode) 
         VALUES ($1, $2, ''comp'')' USING act_consent, act_consent_dir_3;


EXECUTE  'INSERT INTO Person (classCode, name)
        VALUES (''psn'', ''Dr. Ronan Blue'') RETURNING _id' INTO ronan;
EXECUTE 'INSERT INTO Employee (classCode, _player, _scoper, effectiveTime, confidentialityCode, jobCode, pgname)
        VALUES (''emp'', $1, $2, ''[20131108,]'', ''n'',''doc'', ''ronan'')
        RETURNING _id' USING ronan, org1 INTO emp_ronan;
EXECUTE 'INSERT INTO Employee (classCode, _player, _scoper, effectiveTime, confidentialityCode, jobCode, pgname)
        VALUES (''emp'', $1, $2, ''[20131108,]'', ''n'', ''res'', ''researcher'')
        RETURNING _id' USING ronan, org1 INTO emp_ronan_r;


-- 

        -- EXECUTE 'INSERT INTO consent(roleId, action, purposeOfUse, informationReference)
--         VALUES($1, ''allow'', ''research'', ''diabetes'')' USING pat_mary;

/* Here goes RLS: if the user has research capability
AND the acts belong to a patient that has consented for research of diabetes information
AND the acts are in the context of the care provision 'T' for diabetes
*/
--  ALTER TABLE act SET ROW SECURITY FOR ALL TO (
--    EXISTS (
-- /* An employee with research capability */
--      SELECT 1
--      FROM employee emp
--      WHERE emp.pgname = current_user
--      AND emp.jobCode='res'
--     )
-- );


--     AND
--     SELECT 1
--     LEFT JOIN participation part_pat ON part_pat.act_id=act.id
--     LEFT JOIN patient pat on part_pat.role_id=pat.id
--     LEFT JOIN person pers on pat.id=pers.id
--     WHERE pers.name='Mary White'

--     AND act.classCode='pcpr'
--     AND act.code='evn'
--     AND act.code='T'
-- );



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
