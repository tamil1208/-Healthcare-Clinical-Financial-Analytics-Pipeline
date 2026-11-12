-- Creating Views of tables

-- 1.  The Dimension Table vw_dim_patients
create view vw_dim_patients as
select 
	patient_id,
    age_group,
    gender,
    insurance_type,
    smoking_status,
    alcohol_use,
    exercise_level,
    charlson_index,
    case when charlson_index = 0 then 'None'
		when charlson_index between 1 and 2 then 'Mild'
        when charlson_index between 3 and 4 then 'Moderate'
        else 'High' end as risk_severity
from patients;

-- 2. Central Fact Table vw_fact_outcomes
create view vw_fact_outcomes as 
select 
	patient_id,
    admission_date,
    discharge_date,
    length_of_stay_days,
    icu_admission,
    icu_days,
    in_hospital_death,
    discharge_disposition,
    readmitted_30d,
    days_to_readmission,
    primary_drg,
    total_charges_usd
from outcomes;

-- 3. Lab Results View vw_fact_lab_summaries
create view vw_fact_lab_summaries as 
select 
	patient_id,
    count(lab_id) as total_tests,
    -- This adds up all the 1s to tell exactly how many tests failed
    sum(is_abnormal) as abnormal_tests
from lab_results
group by patient_id;

-- 4. Medicines view
create view vw_fact_medicines as
select 
	patient_id,
    indication as disease_treated,
    adherence_pct
from medicines;

-- 5. Primary Diagnoses View
create view vw_fact_diagnoses as 
select 
	visit_id,
    patient_id,
    visit_date,
    primary_diagnosis,
    primary_icd10 as icd10_code
from diagnoses;

-- 6. Reference View charlson index
create view vw_dim_cci_reference as
select 
	condition_name,
    cci_weight
from charlson_comorbidity_index;






