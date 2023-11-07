SELECT program_id  INTO @ncd_program FROM program p WHERE uuid='515796ec-bf3a-11e7-abc4-cec278b6b50a';
select program_workflow_id into @ncdWorkflow from program_workflow where uuid = '51579bce-bf3a-11e7-abc4-cec278b6b50a';
SET @locale='en';

DROP TABLE IF EXISTS ncd_program;
CREATE TEMPORARY TABLE ncd_program
(
patient_id int,
patient_program_id int, 
emr_id varchar(30),
program_name varchar(50),
date_enrolled date,
date_completed date,
final_program_status varchar(100),
clinical_status varchar(50),
created_by varchar(50)
);


insert into ncd_program(patient_id,patient_program_id, emr_id,program_name,date_enrolled,date_completed,final_program_status,created_by)
select  pp.patient_id,pp.patient_program_id,
        patient_identifier(pp.patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) AS emr_id,
		p.name program_name,
		pp.date_enrolled,
		pp.date_completed,
		cn.name final_program_status,
		u.username created_by
from patient_program pp
left outer join program p on pp.program_id =p.program_id 
left outer join users u on pp.creator =u.user_id
left outer join concept_name cn on pp.outcome_concept_id = cn.concept_id and cn.voided=0 and cn.locale='en'
where pp.voided=0 
AND pp.program_id = @ncd_program;

UPDATE ncd_program tgt
SET clinical_status = (
select concept_name(pws.concept_id, @locale) 
from patient_state ps
inner join program_workflow_state pws on ps.state = pws.program_workflow_state_id and program_workflow_id =@ncdWorkflow
inner join patient_program pp on pp.voided =0 and pp.patient_program_id = ps.patient_program_id
where ps.patient_program_id = tgt.patient_program_id
and (ps.end_date is null or ps.end_date = pp.date_completed )
AND ps.voided = 0
order by ps.start_date desc limit 1) ; 

select 
emr_id,
program_name,
date_enrolled,
date_completed,
final_program_status,
clinical_status,
created_by
from ncd_program;