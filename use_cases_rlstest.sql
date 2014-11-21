-- Copyright (c) 2014, Portavita BV Netherlands

DROP USER IF EXISTS research_user;
CREATE USER research_user;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA minirim TO public;
GRANT ALL ON ALL TABLES IN SCHEMA minirim TO public;

-- enable row level security on table Act
ALTER TABLE Act ENABLE ROW LEVEL SECURITY;

-- Prevents access to those acts that are part of a care provision for which the patient has released an opt-out consent.
CREATE POLICY p1 ON Act
	USING (
        Act._id not IN (
            select part._act
            from participation part
             join role r 
             on part._role=r._id
             where part._act=Act._id
             and act.code in (select consent.careProvision 
                    from optoutconsent consent 
                    where consent.patientId = r._id)
             )
        AND 
        Act._id not IN (
            select part._act
            from participation part
             join role r 
             on part._role=r._id
             join actrelationship ar
             on ar._act_source = act._id
             join careprovision cp
             on cp._id=ar._act_target
             where part._act=Act._id
             and cp.code  in (select consent.careProvision 
                    from optoutconsent consent 
                    where consent.patientId = r._id)
             )
        );

SET SESSION AUTHORIZATION research_user;
select * from act;
select * from actrelationship;

--  more RLS examples: axle-healthcare-benchmark/database/postgresql/src/test/regress/sql
