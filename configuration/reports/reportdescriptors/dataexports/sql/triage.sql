CALL initialize_global_metadata();
set @partition = '${partitionNum}';

SELECT encounter_type_id into @EDTriageEnc from encounter_type where uuid = '74cef0a6-2801-11e6-b67b-9e71128cae77';

set @locale = global_property_value('default_locale', 'en');

drop temporary table if exists temp_ED_Triage;
create temporary table temp_ED_Triage
(
patient_id               int(11),        
encounter_id             int(11),      
visit_id                 int(11),      
wellbody_emr_id          varchar(50),
kgh_emr_id               varchar(50), 
loc_registered           varchar(255),   
unknown_patient          varchar(255),   
ED_Visit_Start_Datetime  datetime,     
encounter_datetime       datetime,       
encounter_location       text,       
date_entered             date,
created_by               varchar(255),
provider                 varchar(255), 
Triage_queue_status      varchar(255), 
Triage_Color             varchar(255), 
Triage_Score             int,          
Chief_Complaint          text,         
Weight_KG                double, 
Mobility                 text,         
Respiratory_Rate         double,       
Blood_Oxygen_Saturation  double,       
Pulse                    double,       
Systolic_Blood_Pressure  double,       
Diastolic_Blood_Pressure double,       
Temperature_C            double, 
Response                 text,         
Trauma_Present           text,    
Emergency_signs          text, 
signs_of_shock           text,
dehydration              text,
Neurological             text,         
Burn                     text,         
Glucose                  text,         
Trauma_type              text,         
Digestive                text,         
Pregnancy                text,         
Respiratory              text,         
Pain                     text,         
Other_Symptom            text,         
Clinical_Impression      text,         
Pregnancy_Test           text,         
Glucose_Value            double,
Referral_Destination     varchar(255)
);

insert into temp_ED_Triage (patient_id, encounter_id, visit_id, encounter_datetime, date_entered, created_by)
select e.patient_id, e.encounter_id, e.visit_id,e.encounter_datetime, e.date_created , person_name_of_user(e.creator) 
from encounter e
where e.encounter_type = @EDTriageEnc and e.voided = 0
AND ((date(e.encounter_datetime) >=@startDate) or (@startDate is null))
AND ((date(e.encounter_datetime) <=@endDate) or (@endDate is null))
;

-- patient level info
DROP TEMPORARY TABLE IF EXISTS temp_ed_patient;
CREATE TEMPORARY TABLE temp_ed_patient
(
patient_id      int(11),      
wellbody_emr_id varchar(50),
kgh_emr_id      varchar(50),  
loc_registered  varchar(255),  
unknown_patient varchar(255)
);
   
insert into temp_ed_patient(patient_id)
select distinct patient_id from temp_ED_Triage;

create index temp_ed_patient_pi on temp_ed_patient(patient_id);

-- identifiers
UPDATE temp_ed_patient SET wellbody_emr_id = patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
UPDATE temp_ed_patient SET kgh_emr_id = patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');

-- unknown patient
UPDATE temp_ed_patient SET unknown_patient = unknown_patient(patient_id);

update temp_ED_Triage t
inner join temp_ed_patient p on p.patient_id = t.patient_id
set	t.wellbody_emr_id = p.wellbody_emr_id,
    t.kgh_emr_id = p.kgh_emr_id,
	t.unknown_patient = p.unknown_patient;


-- Provider
UPDATE temp_ED_Triage SET provider = PROVIDER(encounter_id);

-- encounter location
UPDATE temp_ED_Triage SET encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);

-- location registered
UPDATE temp_ED_Triage SET loc_registered = loc_registered(patient_id);

-- ED Visit Start Datetime
UPDATE temp_ED_Triage t
inner join visit v on t.visit_id = v.visit_id
set t.ED_Visit_Start_Datetime = v.date_started;

set @queue_status = concept_from_mapping('PIH','Triage queue status');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@queue_status
set t.Triage_queue_status = concept_name(o.value_coded,@locale);

set @triage_color = concept_from_mapping('PIH','Triage color classification');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@triage_color
set t.Triage_Color = concept_name(o.value_coded,@locale);

set @triage_score = concept_from_mapping('PIH','Triage score');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@triage_score
set t.Triage_Score = o.value_numeric;

set @chief_complaint = concept_from_mapping('CIEL','160531');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@chief_complaint
set t.Chief_Complaint = o.value_text;

set @weight = concept_from_mapping('PIH','WEIGHT (KG)');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@weight
set t.Weight_KG = o.value_numeric;

set @mobility = concept_from_mapping('PIH','Mobility');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@mobility
set t.Mobility = concept_name(o.value_coded,@locale);

set @rr = concept_from_mapping('PIH','RESPIRATORY RATE');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id = @rr
set t.Respiratory_Rate = o.value_numeric;

set @o2 = concept_from_mapping('PIH','BLOOD OXYGEN SATURATION');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@o2
set t.Blood_Oxygen_Saturation = o.value_numeric;

set @pulse = concept_from_mapping('PIH','PULSE');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@pulse
set t.Pulse = o.value_numeric;

set @sbp = concept_from_mapping('PIH','SYSTOLIC BLOOD PRESSURE');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id = @sbp
set t.Systolic_Blood_Pressure = o.value_numeric;

set @dbp = concept_from_mapping('PIH','DIASTOLIC BLOOD PRESSURE');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@dbp
set t.Diastolic_Blood_Pressure = o.value_numeric;

set @temp = concept_from_mapping('PIH','TEMPERATURE (C)');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','TEMPERATURE (C)')
set t.Temperature_C = o.value_numeric;

set @triage_diagnosis =concept_from_mapping('PIH','Triage diagnosis');
set @response = concept_from_mapping('PIH','Response triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @response
set t.Response = concept_name(o.value_coded,@locale);

set @trauma = concept_from_mapping('PIH','Traumatic Injury');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
  and o.value_coded = @trauma
set t.Trauma_Present = concept_name(o.value_coded,@locale);

set @emergencySigns = concept_from_mapping('PIH','Emergency signs');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @emergencySigns
set t.Emergency_signs = concept_name(o.value_coded,@locale);

set @shock = concept_from_mapping('PIH','14701');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @shock
set t.signs_of_shock = concept_name(o.value_coded,@locale);

set @dehydration = concept_from_mapping('PIH','14702');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @dehydration
set t.dehydration = concept_name(o.value_coded,@locale);

set @neuro = concept_from_mapping('PIH','Neurological triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @neuro
set t.Neurological = concept_name(o.value_coded,@locale);

set @burn = concept_from_mapping('PIH','Burn triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @burn
set t.Burn = concept_name(o.value_coded,@locale);

set @glucose = concept_from_mapping('PIH','Glucose triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @glucose
set t.Glucose = concept_name(o.value_coded,@locale);

set @tt =  concept_from_mapping('PIH','Trauma triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @tt
set t.Trauma_type = concept_name(o.value_coded,@locale);

set @digestive = concept_from_mapping('PIH','Digestive triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @digestive
set t.Digestive = concept_name(o.value_coded,@locale);

set @pregancy = concept_from_mapping('PIH','10721');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @pregancy
set t.Pregnancy = concept_name(o.value_coded,@locale);

set @respiratory =  concept_from_mapping('PIH','Respiratory triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set =@respiratory 
set t.Respiratory = concept_name(o.value_coded,@locale);

set @pain = concept_from_mapping('PIH','Pain triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @pain
set t.Pain = concept_name(o.value_coded,@locale);

set @other = concept_from_mapping('PIH','Other triage symptom');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @other
set t.Other_Symptom = concept_name(o.value_coded,@locale);

set @ci = concept_from_mapping('PIH','CLINICAL IMPRESSION COMMENTS');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@ci
set t.Clinical_Impression = o.value_text;

set @pregancy_test = concept_from_mapping('PIH','B-HCG');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@pregancy_test
set t.Pregnancy_Test = concept_name(o.value_coded,@locale);

set @gv = concept_from_mapping('PIH','SERUM GLUCOSE');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id = @gv
set t.Glucose_Value = o.value_numeric;

set @destination = concept_from_mapping('PIH','14818');
update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =@destination
set t.Referral_Destination = concept_name(o.value_coded,@locale);

-- final output of data
Select
wellbody_emr_id,
kgh_emr_id,
concat(@partition,"-",encounter_id) encounter_id,
concat(@partition,"-",visit_id) visit_id,
loc_registered,
unknown_patient,
ED_Visit_Start_Datetime,
encounter_datetime,
encounter_location,
provider,
date_entered,
created_by,
Triage_queue_status,
Triage_Color,
Triage_Score,
Chief_Complaint,
Weight_KG,
Emergency_signs,
Mobility,
Respiratory_Rate,
Blood_Oxygen_Saturation,
Pulse,
Systolic_Blood_Pressure,
Diastolic_Blood_Pressure,
Temperature_C,
Response,
Trauma_Present,
signs_of_shock,
dehydration,
Neurological,
Burn,
Glucose,
Trauma_type,
Digestive,
Pregnancy,
Respiratory,
Pain,
Other_Symptom,
Clinical_Impression,
Pregnancy_Test,
Glucose_Value,
Referral_Destination
from temp_ED_Triage;
