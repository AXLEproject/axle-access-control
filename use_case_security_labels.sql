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