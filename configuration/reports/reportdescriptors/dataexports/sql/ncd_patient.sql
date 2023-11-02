SELECT encounter_type_id  INTO @ncd_init FROM encounter_type et WHERE uuid='ae06d311-1866-455b-8a64-126a9bd74171';
SELECT encounter_type_id  INTO @ncd_followup FROM encounter_type et WHERE uuid='5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
SELECT program_id  INTO @ncd_program FROM program p WHERE uuid='515796ec-bf3a-11e7-abc4-cec278b6b50a';
SET @partition = '${partitionNum}';


DROP TABLE IF EXISTS ncd_patient;
CREATE TABLE ncd_patient (
patient_id int, 
encounter_id int, 
emr_id varchar(50),
hiv varchar(30),
comorbidities varchar(30),
diabetes boolean,
hypertension  boolean,
heart_failure boolean,
chronic_lung_disease boolean,
chronic_kidney_disease boolean,
liver_cirrhosis_hepb boolean,
palliative_care boolean,
sickle_cell boolean,
other_ncd boolean,
diabetes_type varchar(100),
hypertension_type varchar(30), 
rheumatic_heart_disease boolean, 
congenital_heart_disease boolean,
nyha_classification varchar(30),
lung_disease_type varchar(500), 
ckd_stage varchar(100),
sickle_cell_type varchar(100),
recent_program_id int,
next_appointment_date date,
enroll_location varchar(30),
date_of_enrollment date,
currently_enrolled boolean,
dead boolean, 
date_of_death date,
unenrollment_date date,
name varchar(50), 
family_name varchar(50),
dob date,
dob_estimated boolean,
current_age int, 
gender varchar(10),
other_ncd_type varchar(500),
most_recent_visit_date date,
disposition varchar(50)
);


DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
SELECT patient_id,encounter_id, encounter_type ,encounter_datetime, date_created 
FROM encounter e 
WHERE e.encounter_type IN (@ncd_init)
-- AND e.patient_id=112048
AND e.voided = 0;


DROP TABLE IF EXISTS recent_encounter;
CREATE TABLE recent_encounter
SELECT max(encounter_datetime) encounter_datetime, patient_id
FROM temp_encounter
GROUP BY patient_id;

create index temp_encounter_ci1 on temp_encounter(encounter_id);

DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.value_drug, o.comments, o.date_created, o.obs_datetime
from obs o inner join temp_encounter t on o.encounter_id = t.encounter_id
where o.voided = 0;

INSERT INTO ncd_patient(patient_id, emr_id, encounter_id,  name, family_name, 
current_age, gender, dead, date_of_death, dob)
SELECT patient_id,
patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) AS emr_id,
encounter_id,
person_name(patient_id),
person_family_name(patient_id),
current_age_in_years(patient_id),
gender(patient_id), 
dead(patient_id),
death_date(patient_id),
birthdate(patient_id)
FROM temp_encounter;

UPDATE ncd_patient tgt 
INNER JOIN person p ON tgt.patient_id = p.person_id
AND p.voided=0
SET tgt.dob_estimated= p.birthdate_estimated;

UPDATE ncd_patient
SET diabetes = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '3720');

UPDATE ncd_patient
SET hypertension = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '903');

UPDATE ncd_patient
SET heart_failure = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '3468');

UPDATE ncd_patient
SET chronic_lung_disease = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '6768');

UPDATE ncd_patient
SET chronic_kidney_disease = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '3699');

UPDATE ncd_patient
SET liver_cirrhosis_hepb = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '3714');

UPDATE ncd_patient
SET palliative_care = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '10359');

UPDATE ncd_patient
SET sickle_cell = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '7908');

UPDATE ncd_patient
SET other_ncd = answer_exists_in_encounter(encounter_id, 'PIH', '10529','PIH', '5622');

UPDATE ncd_patient
SET hypertension_type = obs_value_coded_list_from_temp(encounter_id, 'PIH', '11940','en');

UPDATE ncd_patient
SET diabetes_type = CASE WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '6692', null) THEN 'Type 2 DM'
WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '6691', null) THEN 'Type 1 DM'
WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '3720', null) THEN 'DM not yet specified' 
ELSE NULL
END;

UPDATE ncd_patient
SET rheumatic_heart_disease = answer_exists_in_encounter(encounter_id, 'PIH', '3064','PIH', '221');

UPDATE ncd_patient
SET congenital_heart_disease = answer_exists_in_encounter(encounter_id, 'PIH', '3064','PIH', '3131');

UPDATE ncd_patient
SET nyha_classification = obs_value_coded_list_from_temp(encounter_id, 'PIH', '3139','en');

UPDATE ncd_patient
SET lung_disease_type = obs_value_coded_list_from_temp(encounter_id, 'PIH', '14599','en');

UPDATE ncd_patient
SET ckd_stage = obs_value_coded_list_from_temp(encounter_id, 'PIH', '12501','en');

UPDATE ncd_patient
SET sickle_cell_type = 
CASE WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '7908', null) THEN 'Sickle-cell anemia (SS)'
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '7915', null) THEN 'Sickle-cell trait (AS)'
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '14923', null) THEN 'Sickle-cell beta thalassemia (SB)' 
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '12715', null) THEN 'Sickle-cell hemoglobin C disease (SC)' 
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '10134', null) THEN 'Other hemoglobinopathy' 
     ELSE NULL
     END;

UPDATE ncd_patient
SET next_appointment_date = obs_value_datetime_from_temp(encounter_id, 'PIH','5096'); 

UPDATE ncd_patient
SET enroll_location = currentProgramLocation(patient_id,@ncd_program);

UPDATE ncd_patient
SET recent_program_id = mostRecentPatientProgramId(patient_id, @ncd_program);

UPDATE ncd_patient tgt
INNER JOIN patient_program pp ON tgt.recent_program_id=pp.patient_program_id
SET date_of_enrollment=pp.date_enrolled;

UPDATE ncd_patient tgt
SET currently_enrolled=CASE WHEN tgt.date_of_enrollment IS NOT NULL AND tgt.dead IS NOT NULL THEN TRUE ELSE FALSE END ;


set @disp = concept_from_mapping('PIH','8620');
UPDATE ncd_patient tgt 
INNER JOIN temp_obs o ON o.encounter_id=tgt.encounter_id
AND o.concept_id= @disp 
SET disposition= concept_name(value_coded,@locale);

UPDATE ncd_patient
SET hiv = obs_value_coded_list_from_temp(encounter_id, 'PIH', '1169','en');

UPDATE ncd_patient
SET comorbidities = obs_value_coded_list_from_temp(encounter_id, 'PIH', '12976','en');

UPDATE ncd_patient
SET other_ncd_type = obs_value_text_from_temp(encounter_id, 'PIH', '7416');

UPDATE ncd_patient tgt 
INNER JOIN recent_encounter re ON tgt.patient_id = re.patient_id 
SET most_recent_visit_date = re.encounter_datetime ;

SELECT 
emr_id,
hiv,
comorbidities,
diabetes,
hypertension,
heart_failure,
chronic_lung_disease,
chronic_kidney_disease,
liver_cirrhosis_hepb,
palliative_care,
sickle_cell,
other_ncd,
diabetes_type,
hypertension_type,
rheumatic_heart_disease,
congenital_heart_disease,
nyha_classification,
lung_disease_type,
ckd_stage,
sickle_cell_type,
next_appointment_date,
enroll_location,
date_of_enrollment,
currently_enrolled,
dead,
date_of_death,
unenrollment_date,
name,
family_name,
dob,
dob_estimated,
current_age,
gender,
other_ncd_type,
most_recent_visit_date,
disposition
FROM ncd_patient;