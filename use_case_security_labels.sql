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


