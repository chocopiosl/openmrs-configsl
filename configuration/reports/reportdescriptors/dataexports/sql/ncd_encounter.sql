select encounter_type_id INTO @NCDInitial FROM encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171'; 
select encounter_type_id INTO @NCDFollowup FROM encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c'; 
set @locale = global_property_value('default_locale', 'en');
set @partition = '${partitionNum}';

set @yes = concept_name(concept_from_mapping('PIH','YES'),@locale);

drop temporary table if exists temp_ncd;
create temporary table temp_ncd
(
 patient_id                          int(11),          
 emr_id                              varchar(50),      
 encounter_id                        int(11),          
 encounter_datetime                  datetime,         
 date_created                        datetime,         
 visit_id                            int(11),          
 provider                            varchar(255),     
 creator_user_id                     int(11),          
 creator                             varchar(255),     
 encounter_location_id               int(11),          
 encounter_location                  varchar(255),     
 encounter_type_id                   int(11),          
 encounter_type                      varchar(255),     
 social_support                      bit,              
 social_support_type                 varchar(255),     
 missed_school                       bit,              
 days_lost_schooling                 double,           
 hiv                                 varchar(255),  
 risk_factors                        text, 
 comorbidities                       varchar(255),     
 bp_systolic                         double,           
 bp_diastolic                        double,           
 glucose_fingerstick                 varchar(255),     
 fbg_level                           double,        
 rbg_level                           double,        
 bmi                                 varchar(255),     
 obesity                             bit,              
 number_days_hospitalized            double,           
-- hospitalizations_last_12_months     double,        
 last_hospitalization_discharge_date datetime,      
 last_hospitalization_outcome        varchar(255),  
 number_hospitalizations_ncd                double,        
 hospitalization_dka_last_12_months  boolean,       
 diabetes                            bit,              
 hypertension                        bit,              
 heart_failure                       bit,              
 chronic_lung_disease                bit,              
 chronic_kidney_disease              bit,              
 liver_cirrhosis_hepb                bit,              
 palliative_care                     bit,              
 sickle_cell                         bit,              
 other_ncd                           bit,              
 diabetes_onset_date                 date,          
 hypertension_onset_date             date,          
 heart_failure_onset_date            date,          
 chronic_lung_disease_onset_date     date,          
 chronic_kidney_disease_onset_date   date,          
 liver_cirrhosis_hepb_onset_date     date,          
 palliative_care_onset_date          date,          
 sickle_cell_onset_date              date,          
 other_ncd_onset_date                date,          
 treatment_with_hydroxyurea          boolean,       
 reason_no_hydroxyurea               varchar(255),     
 diabetes_type                       varchar(255),     
 diabetes_indicators_obs_group       int(11),          
 diabetes_control                    varchar(255),     
 diabetes_on_insulin                 bit,              
 diabetes_home_glucometer            bit,           --  
 lab_order_hba1c                     boolean,       --  
 hypertension_type                   varchar(255),     
 hypertension_stage                  varchar(255),     
 hypertension_indicators_obs_group   int(11),          
 hypertension_controlled             varchar(255),     
 rheumatic_heart_disease             bit,              
 congenital_heart_disease            bit,              
 nyha_classification                 varchar(255),     
 lung_disease_type                   text,             
 ckd_stage                           varchar(255),     
 ckd_indicators_obs_group            int(11),          
 ckd_controlled                      varchar(255),     
 liver_indicators_obs_group          int(11),          
 liver_disease_controlled            varchar(255),     
 sickle_cell_type                    varchar(255),     
 sickle_cell_complications           text, 
 next_appointment_date               date,             
 disposition                         varchar(255),     
 transfer_site                       varchar(255),  
 echooptions                         text,  
 echocomment                         text,  
 echocardiogram_findings             text,     
 on_on_ace_inhibitor_group_id        int,           
 on_ace_inhibitor                    varchar(255),    
 on_beta_blocker                     varchar(255),       
 secondary_antibiotic_prophylaxis    boolean,       
 cardiac_surgery_scheduled           varchar(255),       
 type_cardiac_surgery                varchar(255),  
 cardiac_surgery_performed_date      date,          
 cardiac_surgery_performed           boolean,          
 scd_penicillin_treatment            boolean,          
 scd_folic_acid_treatment            boolean,       
 transfusion_past_12_months          boolean,       
 asthma_severity                     varchar(255),      
 nighttime_waking_asthma             varchar(255),    
 nighttime_count                     int,              
 symptoms_2x_week_asthma             varchar(255),    
 symptoms_2x_count                   int,              
 inhaler_for_symptoms_2x_week_asthma varchar(255),    
 inhaler_count                       int,           
 limitation_obs_group_id             int,              
 activity_limitation_asthma          varchar(255),      
 activity_count                      int,              
 asthma_control_GINA                 varchar(255),   
 echocardiogram_obs_group_id         int,              
 echocardiogram_date                 date,             
 diabetic_comma                      boolean,          
 diabetic_without_comma              boolean,       
 lab_tests_ordered                   text, 
 index_asc                           int,              
 index_desc                          int            
);

insert into temp_ncd
	(patient_id,
	encounter_id,
	encounter_datetime,
	date_created,
	visit_id,
	creator_user_id,
	encounter_location_id,
	encounter_type_id)
select 
	patient_id,
	encounter_id,
	e.encounter_datetime ,
	e.date_created ,
	e.visit_id ,
	e.creator ,
	e.location_id ,
	e.encounter_type 
from encounter e
where e.voided = 0
and e.encounter_type in (@NCDInitial,@NCDFollowup)
and (DATE(encounter_datetime) >=  date(@startDate) or @startDate is null)
and (DATE(encounter_datetime) <=  date(@endDate) or @endDate is null)
;	

-- encounter level columns
update temp_ncd
set creator = person_name_of_user(creator_user_id);

update temp_ncd
set encounter_location = location_name(encounter_location_id);

update temp_ncd
set encounter_type = encounterName(encounter_type_id);

update temp_ncd
set provider = provider(encounter_id);


-- patient level columns
drop temporary table if exists temp_ncd_patients;
create temporary table temp_ncd_patients
	(patient_id int(11),
	emr_id varchar(255));

insert into temp_ncd_patients (patient_id)
select distinct patient_id from temp_ncd;

update temp_ncd_patients t
set t.emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_ncd t 
inner join temp_ncd_patients p on p.patient_id = t.patient_id
set t.emr_id = p.emr_id;

-- obs level columns
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.comments, o.date_created  
,o.obs_datetime
from obs o
inner join temp_ncd t on t.encounter_id = o.encounter_id
where o.voided = 0 
;

DROP TEMPORARY TABLE IF EXISTS limitation_obs_id;
CREATE TEMPORARY TABLE limitation_obs_id
SELECT encounter_id, obs_id AS obs_group_id
FROM temp_obs
WHERE concept_id=concept_from_mapping('PIH','14587');

update temp_ncd t
set echocardiogram_obs_group_id=obs_group_id_of_value_coded_from_temp(encounter_id,'PIH','8614','PIH','3763');

UPDATE temp_ncd t
SET echocardiogram_date=obs_from_group_id_value_datetime_from_temp(t.echocardiogram_obs_group_id,'PIH','12847');

update temp_ncd t
set next_appointment_date = DATE(obs_value_datetime_from_temp(encounter_id, 'PIH','5096'));

update temp_ncd t
set disposition = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','8620',@locale)
		WHEN concept_name(concept_from_mapping('PIH','2224'),@locale) then 'Laboratory tests outstanding'
		WHEN concept_name(concept_from_mapping('PIH','12358'),@locale) then 'No action taken'
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','8620',@locale)
	END;

update temp_ncd t
set social_support = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14443',0));

update temp_ncd t
set social_support_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','2156',@locale);

update temp_ncd t
set missed_school = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','5629',0));

update temp_ncd t
set days_lost_schooling = obs_value_numeric_from_temp(encounter_id, 'PIH','14446');

update temp_ncd t
set hiv = obs_value_coded_list_from_temp(encounter_id, 'PIH','1169',@locale);

-- risk factors
set @yes_concept = concept_from_mapping('PIH','YES');
set @alcohol = concept_from_mapping('CIEL','159449');
set @smoking = concept_from_mapping('CIEL','163731');
set @indoor_cooking = concept_from_mapping('CIEL','159365');
set @history_pulmonary_tb = concept_from_mapping('PIH','14582');
set @occupational_exposure = concept_from_mapping('CIEL','167822');
set @seasonal_allergies = concept_from_mapping('PIH','14584');
set @excessive_salt = concept_from_mapping('PIH','14452');
set @maggie_seasoning = concept_from_mapping('CIEL','167878');
set @ace_inhibitors = concept_from_mapping('CIEL','167998');
set @nsaids = concept_from_mapping('PIH','14712');
set @nephrotoxic_drugs = concept_from_mapping('PIH','14713');
set @history_cardiac_disease = concept_from_mapping('CIEL','140231');

update temp_ncd t
set risk_factors = (
	select group_concat(concept_name(concept_id,@locale) SEPARATOR '|') from temp_obs o
	where o.encounter_id = t.encounter_id
	and value_coded = @yes_concept
	and obs_group_id is null
	and concept_id in (@alcohol,@smoking,@indoor_cooking,@history_pulmonary_tb,
		@occupational_exposure,@seasonal_allergies,@excessive_salt,@maggie_seasoning,
		@ace_inhibitors,@nsaids,@nephrotoxic_drugs,@history_cardiac_disease)
	group by encounter_id);


update temp_ncd t
set comorbidities = obs_value_coded_list_from_temp(encounter_id, 'PIH','12976',@locale);

update temp_ncd t
set bp_systolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5085');

update temp_ncd t
set bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5086');

update temp_ncd t
set glucose_fingerstick = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1065')=@yes, 'FBG',
		if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1066')=@yes, 'RBG',null));

update temp_ncd t 
set fbg_level = obs_value_numeric_from_temp(encounter_id, 'CIEL','160912');

update temp_ncd t 
set rbg_level = obs_value_numeric_from_temp(encounter_id, 'CIEL','887');

	
update temp_ncd t
set bmi = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','14126',@locale)
		WHEN concept_name(concept_from_mapping('PIH','7507'),@locale) then 'Moderate obese'
		WHEN concept_name(concept_from_mapping('PIH','14455'),@locale) then 'Severe obese'
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','14126',@locale)
	END;


update temp_ncd t
set obesity = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','1293','PIH','7507')=@yes, 1,
		if(obs_single_value_coded_from_temp(encounter_id, 'PIH','1734','PIH','7507')=@yes, 0,null));

update temp_ncd t
set number_days_hospitalized = obs_value_numeric_from_temp(encounter_id, 'PIH','2872');

-- update temp_ncd t
-- set hospitalizations_last_12_months = obs_value_numeric_from_temp(encounter_id, 'PIH','5704');

update temp_ncd t
set last_hospitalization_discharge_date = obs_value_datetime_from_temp(encounter_id, 'PIH','3800');

update temp_ncd t
set last_hospitalization_outcome = obs_value_coded_list_from_temp(encounter_id, 'PIH','15159',@locale);

update temp_ncd t
set number_hospitalizations_ncd = obs_value_numeric_from_temp(encounter_id, 'PIH','15160');

update temp_ncd t
set hospitalization_dka_last_12_months =  value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','15158',0));

update temp_ncd t
set diabetes = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3720')=@yes, 1,null);

update temp_ncd t
set diabetes_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3720'), 'PIH','7538');
 

update temp_ncd t
set hypertension = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','903')=@yes, 1,null);

update temp_ncd t
set hypertension_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','903'), 'PIH','7538');
 

update temp_ncd t
set heart_failure = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3468')=@yes, 1,null);

update temp_ncd t
set heart_failure_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3468'), 'PIH','7538');
 

update temp_ncd t
set chronic_lung_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','6768')=@yes, 1,null);

update temp_ncd t
set chronic_lung_disease_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','6768'), 'PIH','7538');

update temp_ncd t
set chronic_kidney_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3699')=@yes, 1,null);

update temp_ncd t
set chronic_kidney_disease_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3699'), 'PIH','7538');


update temp_ncd t
set liver_cirrhosis_hepb = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3714')=@yes, 1,null);

update temp_ncd t
set liver_cirrhosis_hepb_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3714'), 'PIH','7538');


update temp_ncd t
set palliative_care = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','10359')=@yes, 1,null);

update temp_ncd t
set palliative_care_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','10359'), 'PIH','7538');


update temp_ncd t
set sickle_cell = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','7908')=@yes, 1,null);

update temp_ncd t
set sickle_cell_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','7908'), 'PIH','7538');

update temp_ncd t
set other_ncd = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','5622')=@yes, 1,null);

update temp_ncd t
set other_ncd_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','5622'), 'PIH','7538');

update temp_ncd t
set treatment_with_hydroxyurea  = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14870',0));

update temp_ncd t
set reason_no_hydroxyurea = obs_value_coded_list_from_temp(encounter_id, 'PIH','15169',@locale);

update temp_ncd t
set diabetes_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','1715',@locale);

update temp_ncd t
set diabetes_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14469',0 );

update temp_ncd t
set  diabetes_control = obs_from_group_id_value_coded_list_from_temp(diabetes_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set diabetes_home_glucometer = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14503',0));

update temp_ncd t
set diabetes_on_insulin = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','6756',0));

set @dx = concept_from_mapping('PIH','3064');
set @type_1_dm = concept_from_mapping('PIH','6691');
set @type_2_dm = concept_from_mapping('PIH','6692');
set @gest_dm = concept_from_mapping('PIH','6693');
set @unspec_dm = concept_from_mapping('PIH','3720');
update temp_ncd t
set diabetes_type = 
(select concept_name(o.value_coded,@locale)
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@type_1_dm,@type_2_dm,@gest_dm,@unspec_dm)
ORDER BY FIELD(o.value_coded,@unspec_dm)
limit 1);

update temp_ncd t
set hypertension_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14462',0);

update temp_ncd t
set  hypertension_controlled = obs_from_group_id_value_coded_list_from_temp(hypertension_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set hypertension_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','11940',@locale);

update temp_ncd t
set hypertension_stage = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','12699',@locale)
		WHEN concept_name(concept_from_mapping('PIH','12697'),@locale) then 'Pre-HTN'
		WHEN concept_name(concept_from_mapping('PIH','12698'),@locale) then '1 (Mild)'
		WHEN concept_name(concept_from_mapping('PIH','12695'),@locale) then '2 (Moderate)'		
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','12699',@locale)
	END;

update temp_ncd t
set rheumatic_heart_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','3064','PIH','221')=@yes, 1,null);

update temp_ncd t
set congenital_heart_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','3064','PIH','3131')=@yes, 1,null);

update temp_ncd t
set nyha_classification = obs_value_coded_list_from_temp(encounter_id, 'PIH','3139',@locale);

set @copd = concept_from_mapping('PIH','3716');
set @bronchiectasis = concept_from_mapping('PIH','7952');
set @asthma = concept_from_mapping('PIH','5');
set @corPulmonale = concept_from_mapping('PIH','4000');
update temp_ncd t
set lung_disease_type = 
(select GROUP_CONCAT(concept_name(o.value_coded,@locale) separator ' | ')
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@copd,@bronchiectasis,@asthma,@corPulmonale)
 group by encounter_id
);

update temp_ncd t
set ckd_stage = obs_value_coded_list_from_temp(encounter_id, 'PIH','12501',@locale);

UPDATE temp_ncd t
SET echooptions = obs_from_group_id_value_coded_list(echocardiogram_obs_group_id,'PIH','3763',@locale);

UPDATE temp_ncd t
SET echocomment = obs_from_group_id_value_text(echocardiogram_obs_group_id, 'PIH', '8596');

UPDATE temp_ncd t
SET echocardiogram_findings =  concat(concat(echooptions,'| '),echocomment );

update temp_ncd t
set ckd_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14717',0);

update temp_ncd t
set  ckd_controlled = obs_from_group_id_value_coded_list_from_temp(ckd_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set liver_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14827',0);

update temp_ncd t
set  liver_disease_controlled = obs_from_group_id_value_coded_list_from_temp(liver_indicators_obs_group, 'PIH','11506',@locale);

set @sickle_cell_trait = concept_from_mapping('PIH','7915');
set @sickle_anemia = concept_from_mapping('PIH','7908');
set @beta_thalassemia = concept_from_mapping('PIH','14923');
set @hemoglobin_c  = concept_from_mapping('PIH','12715');
set @other_hemoglobinopathy  = concept_from_mapping('PIH','10134');

update temp_ncd t
set sickle_cell_type = 
(select concept_name(o.value_coded,@locale)
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@sickle_cell_trait,@sickle_anemia,@beta_thalassemia,@hemoglobin_c,@other_hemoglobinopathy)
limit 1);

update temp_ncd t
set sickle_cell_complications = obs_value_coded_list_from_temp(encounter_id,'PIH', '15157',@locale);


update temp_ncd t
set transfer_site = obs_value_datetime_from_temp(encounter_id, 'PIH','14424');

update temp_ncd t
set transfer_site = obs_value_coded_list_from_temp(encounter_id, 'PIH','14424',@locale);

UPDATE temp_ncd t
SET on_on_ace_inhibitor_group_id = obs_id_from_temp(encounter_id, 'PIH','14724', 0);


update temp_ncd t
set on_ace_inhibitor = obs_from_group_id_value_coded_list_from_temp(on_on_ace_inhibitor_group_id,'PIH','14531',@locale );

update temp_ncd t
set on_beta_blocker = obs_value_coded_list_from_temp(encounter_id,'PIH', '14723',@locale);

update temp_ncd t
set secondary_antibiotic_prophylaxis = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','15168',0));

update temp_ncd t
set cardiac_surgery_scheduled = obs_value_coded_list_from_temp(encounter_id,'PIH', '15165',@locale);

update temp_ncd t
set type_cardiac_surgery = obs_value_coded_list_from_temp(encounter_id,'PIH', '7887',@locale);

update temp_ncd t
set cardiac_surgery_performed = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10484','PIH','7827')=@yes, 1,null);

update temp_ncd t
set cardiac_surgery_performed_date = obs_value_datetime_from_temp(encounter_id, 'PIH','10485');

update temp_ncd t
set scd_penicillin_treatment = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14857','PIH','784')=@yes, 1,null);

update temp_ncd t
set scd_folic_acid_treatment = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14857','PIH','257')=@yes, 1,null);

update temp_ncd t
set transfusion_past_12_months = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','7868',0));

update temp_ncd t
set asthma_severity = obs_value_coded_list_from_temp(encounter_id,'PIH', '7405',@locale);

update temp_ncd t
set nighttime_waking_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11731',@locale);
UPDATE temp_ncd t
SET nighttime_count = if(nighttime_waking_asthma=@yes, 1, 0);
	
update temp_ncd t
set symptoms_2x_week_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11803',@locale);
UPDATE temp_ncd t
SET symptoms_2x_count = if(symptoms_2x_week_asthma=@yes, 1, 0);

update temp_ncd t
set inhaler_for_symptoms_2x_week_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11991',@locale);
UPDATE temp_ncd t
SET inhaler_count = if(inhaler_for_symptoms_2x_week_asthma=@yes, 1, 0);

UPDATE temp_ncd t
INNER JOIN limitation_obs_id l ON t.encounter_id=l.encounter_id
SET activity_limitation_asthma=obs_from_group_id_value_coded_list_from_temp(l.obs_group_id, 'PIH', '11925',@locale);

UPDATE temp_ncd t
SET activity_count = if(activity_limitation_asthma=@yes, 1, 0);

UPDATE temp_ncd t
SET asthma_control_GINA = 
CASE WHEN (nighttime_waking_asthma IS NULL OR symptoms_2x_week_asthma IS NULL OR inhaler_for_symptoms_2x_week_asthma IS NULL OR activity_limitation_asthma IS NULL) THEN NULL 
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count) BETWEEN 3 AND 4) THEN 'Uncontrolled'
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count) BETWEEN 1 AND 2) THEN 'Partly controlled'
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count)  = 0 ) THEN 'Well controlled'
END;

DROP TABLE IF EXISTS order_hb1ac;
CREATE TABLE order_hb1ac AS
SELECT t.encounter_id,CASE WHEN o.concept_id = concept_from_mapping('PIH','7460') THEN TRUE ELSE FALSE END AS "lab_order_hba1c"
FROM temp_ncd t LEFT OUTER JOIN orders o ON t.encounter_id=o.encounter_id AND o.voided=0;

UPDATE temp_ncd t
INNER JOIN order_hb1ac o ON t.encounter_id=o.encounter_id
SET t.lab_order_hba1c= o.lab_order_hba1c;


UPDATE temp_ncd t
SET diabetic_comma = answer_exists_in_encounter(t.encounter_id, 'PIH', '14921', 'PIH','14482');
UPDATE temp_ncd t
SET diabetic_comma=NULL 
WHERE diabetic_comma=FALSE;

UPDATE temp_ncd t
SET diabetic_without_comma = answer_exists_in_encounter(t.encounter_id, 'PIH', '14921', 'PIH','14483');
UPDATE temp_ncd t
SET diabetic_without_comma=NULL 
WHERE diabetic_without_comma=FALSE;

-- lab tests
select order_type_id into @testOrder from order_type ot where uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
update temp_ncd t
set lab_tests_ordered = 
	(select GROUP_CONCAT(concept_name(o.concept_id,@locale) SEPARATOR '|')
	from orders o
	where o.encounter_id = t.encounter_id 
	and voided = 0
	and o.order_type_id = @testOrder
	group by encounter_id);


-- The ascending/descending indexes are calculated ordering on the encounter date
-- new temp tables are used to build them and then joined into the main temp table.
### index ascending
drop temporary table if exists temp_visit_index_asc;
CREATE TEMPORARY TABLE temp_visit_index_asc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_ncd,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime ASC, encounter_id ASC
        ) index_ascending );
CREATE INDEX tvia_e ON temp_visit_index_asc(encounter_id);
update temp_ncd t
inner join temp_visit_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.index_asc = tvia.index_asc;

drop temporary table if exists temp_visit_index_desc;
CREATE TEMPORARY TABLE temp_visit_index_desc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_ncd,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime DESC, encounter_id DESC
        ) index_descending );
       
 CREATE INDEX tvid_e ON temp_visit_index_desc(encounter_id);      
update temp_ncd t
inner join temp_visit_index_desc tvid on tvid.encounter_id = t.encounter_id
set t.index_desc = tvid.index_desc;

select
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
emr_id,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
encounter_datetime,
date_created,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',visit_id),visit_id) "visit_id",
provider,
creator,
encounter_location,
encounter_type,
social_support,
social_support_type,
missed_school,
days_lost_schooling,
hiv,
risk_factors,
comorbidities,
bp_systolic,
bp_diastolic,
glucose_fingerstick,
fbg_level,
rbg_level,
bmi,
obesity,
-- hospitalizations_last_12_months,
last_hospitalization_discharge_date,
last_hospitalization_outcome,
number_hospitalizations_ncd,
hospitalization_dka_last_12_months,
number_days_hospitalized,
diabetes,
hypertension,
heart_failure,
chronic_lung_disease,
chronic_kidney_disease,
liver_cirrhosis_hepb,
palliative_care,
sickle_cell,
other_ncd,
diabetes_onset_date,
hypertension_onset_date,
heart_failure_onset_date,
chronic_lung_disease_onset_date,
chronic_kidney_disease_onset_date,
liver_cirrhosis_hepb_onset_date,
palliative_care_onset_date,
sickle_cell_onset_date,
other_ncd_onset_date,
treatment_with_hydroxyurea,
reason_no_hydroxyurea,
diabetes_type,
diabetes_control,
diabetes_on_insulin,
diabetes_home_glucometer,
lab_order_hba1c,
hypertension_type,
hypertension_stage,
hypertension_controlled,
rheumatic_heart_disease,
congenital_heart_disease,
nyha_classification,
lung_disease_type,
ckd_stage,
ckd_controlled,
liver_disease_controlled,
sickle_cell_type,
sickle_cell_complications,
next_appointment_date,
disposition,
transfer_site,
echocardiogram_findings,
on_ace_inhibitor,
on_beta_blocker,
secondary_antibiotic_prophylaxis,
cardiac_surgery_scheduled,
type_cardiac_surgery,
cardiac_surgery_performed,
cardiac_surgery_performed_date,
scd_penicillin_treatment,
scd_folic_acid_treatment,
transfusion_past_12_months,
asthma_severity,
nighttime_waking_asthma,
symptoms_2x_week_asthma,
inhaler_for_symptoms_2x_week_asthma,
activity_limitation_asthma,
asthma_control_GINA,
echocardiogram_date,
lab_tests_ordered,
index_asc,
index_desc
from temp_ncd 
order by patient_id, encounter_datetime;
