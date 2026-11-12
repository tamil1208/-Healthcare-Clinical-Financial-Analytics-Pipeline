-- Q1. Overall testing volume by month 
select year(test_date) as `Year`, monthname(test_date) month_name,
count(lab_id) total_tests
from lab_results
group by `Year`, month_name 
order by year(test_date), count(lab_id) desc;

-- Q2. Highest percentage of tests with abnormal flags
create view percent_abnormal_test_results as
select 
test_name as Test,
sum(is_abnormal) as abnormal_count,
count(is_abnormal) as total_test_count,
round((avg(is_abnormal)) * 100, 2) percent_abnormal
from lab_results
group by test_name
order by round((avg(is_abnormal)) * 100, 2) desc;

-- Q3. What is the distribution of comorbidities across different age groups and lifestyle factors?
select
age_group,
charlson_index as risk_score,
count(charlson_index) as count_comorbidity
from patients
where charlson_index > 0
group by charlson_index, age_group
order by charlson_index desc, count(charlson_index) desc;

-- Q4. How lifestyle along with age_group affects comorbidity?
select
age_group,
smoking_status,
alcohol_use,
exercise_level,
count(patient_id) as total_patients,
round(avg(charlson_index), 2) as avg_comorbidity_score
from patients
group by age_group,
smoking_status,
alcohol_use,
exercise_level
having count(patient_id) > 100
order by avg_comorbidity_score desc, total_patients desc;

-- Q5. Is there a measurable correlation between poor medication adherence and higher hospital readmission rates?

SELECT 
	m.indication AS disease,
	COUNT(DISTINCT o.patient_id) AS patients_count,
	COUNT(DISTINCT CASE
			WHEN o.readmitted_30d = 1 THEN o.patient_id
		END) AS readmission_count,
	ROUND(AVG(m.adherence_pct), 2) AS avg_medication_adherence,
	ROUND(100 * (COUNT(DISTINCT CASE
					WHEN o.readmitted_30d = 1 THEN o.patient_id
				END) / COUNT(DISTINCT o.patient_id)),
			2) AS readmission_rate
FROM
	outcomes o
		JOIN
	medicines m ON o.patient_id = m.patient_id
GROUP BY m.indication
HAVING patients_count > 100
ORDER BY readmission_rate DESC;


/*
- readmission rate is somewhat correlated to low medication adherence 
- it is also disease dependent, readmission_rate is low even with poor medication adherence
for diseases like hypertension and hypertension
- when done average of medication adherence it is around 80% across diseases 
- disease affecting kidneys and arteries and lungs contributed to higher readmission rates
- overall readmission rates moved between 14 and 20% 
- when grouping results based on medication adherence alone accounting for without disease for 
patients count above 30 readmission rate doesn't seem to correlate with adherence as for 100% adherence
we have 15.41%, but total patients are also higher, for 99 to 100% range rate hovered around 14 to 27% with 
increasing and decreasing 
- for adherence at 69 % the average readmission rate is around 15 to 18%
- when sorted by patients_count in desc order it is observed that
	- with patients 132 and adherence at 86.7% the readmission rate is 11.36%
    - with patients 127 and adherence at 91.5% the readmission rate is 18.90%
    which increased significantly with a slight drop in patients count even with greater adherence
    - finally for patients count of 127 readmission rate was 18.9% with even 79.7% adherence
Hence, readmission rate dependent more on disease type as opposed to medication adherence
    
*/

-- Q6. Which primary diagnoses (ICD-10 codes) are most frequently associated with prolonged ICU stays?
SELECT 
    d.primary_diagnosis disease,
    d.primary_icd10 disease_code,
    COUNT(outcome_id) total_visits,
    COUNT(CASE
        WHEN icu_admission = 1 THEN o.patient_id
    END) icu_visits,
    MAX(icu_days) max_icu_stay,
    ROUND(AVG(CASE
                WHEN o.icu_admission = 1 THEN icu_days
            END),
            2) avg_icu_stay
FROM
    diagnoses d
        JOIN
    outcomes o ON d.patient_id = o.patient_id
GROUP BY primary_diagnosis , primary_icd10
HAVING icu_visits > 10
ORDER BY avg_icu_stay DESC;

-- Q7. How does the average Length of Stay (LOS) differ for patients with multiple comorbidities versus those with none?
SELECT 
    p.charlson_index risk_score,
    CASE
        WHEN p.charlson_index = 0 THEN 'None'
        WHEN p.charlson_index BETWEEN 1 AND 3 THEN 'Mild'
        ELSE 'High'
    END AS severity,
    ROUND(AVG(length_of_stay_days), 2) avg_length_of_stay,
    MAX(length_of_stay_days) max_LOS,
    COUNT(p.patient_id) total_patients,
    SUM(in_hospital_death) deaths_in_hostpital,
    ROUND(100 * AVG(in_hospital_death), 2) rate_of_deaths
FROM
    patients p
        JOIN
    outcomes o ON p.patient_id = o.patient_id
GROUP BY p.charlson_index
ORDER BY avg_length_of_stay DESC , charlson_index DESC;

/*
Interpretation
- first of all there was one patient with charlson index of 7 but the same was never admitted to the hospital as his record not
found in outcomes table
- surprisingly average length of stay topped for mild severity with less than 1 percent hospital deaths
- however, the average length of stay for mild and high severity ranged between 4.73 to 5.3
- astonishingly patients with 0 comorbidity score had one of the highest average length of stay
- there might be other reasons for hospitalization for these patients with none and mild comorbity severity

*/

/*
Financial & Operational Efficiency (Three-Table Joins)
6. Cost Drivers: What factors (specific diagnoses, abnormal lab flags, or ICU requirements) drive the highest total hospital charges?
7. Insurance Disparities: How do hospital charges, mortality rates, and average Length of Stay (LOS) vary across different insurance types?
8. Resource Allocation: Which diagnostic codes generate the highest volume of lab tests per visit, and how many of those tests come back normal (indicating potential over-testing)?

Advanced Insights (Complex Joins & Logic)
9. High-Risk Identification: Can we identify a specific patient profile (combining age, lifestyle, and existing comorbidities) that is at the absolute highest risk for mortality when admitted?
10. The "Frequent Flyer" Analysis: What are the defining characteristics (demographics, common prescriptions, primary diagnoses) of patients who have multiple readmissions within the dataset?
*/

-- Q8. What factors (specific diagnoses, abnormal lab flags, or ICU requirements) drive the highest total hospital charges?

-- Whether icu requirement driving max hospital charges?
select 
Case when icu_admission = 0 then 'Not Required'
else 'Required' end as icu_admission_requirements,
round(avg(total_charges_usd), 2) as avg_charges
from outcomes
group by icu_admission
order by avg_charges desc;

-- How diseases affect the avg total charges when a patient required an icu_admission vs when not?
select 
d.primary_diagnosis,
case when icu_admission = 1 then 'Required'
else 'Not Required' end as icu_admission_requirement,
count(o.patient_id) as total_patients,
round(avg(o.total_charges_usd), 2) avg_charge_per_patient, 
round(sum(o.total_charges_usd), 2) as total_revenue_generated
from outcomes o
join diagnoses d
on o.patient_id = d.patient_id
group by d.primary_diagnosis, icu_admission_requirement
having
	total_patients > 30 -- To filter out statistical noise
order by avg_charge_per_patient desc;	

select sum(total_patients) from disease_effect_on_avg_charge;

-- How abnormal results account for affecting average total charge along with disease?
select 
case when is_abnormal = 1 then 'Abnormal' else 'Normal' end as lab_test_result,
round(avg(o.total_charges_usd), 2) avg_charge_per_patient, 
round(sum(o.total_charges_usd), 2) as total_revenue_generated
from outcomes o
join lab_results l
on o.patient_id = l.patient_id
group by lab_test_result
order by avg_charge_per_patient desc;	

-- Abnormal test results have generated about 212 usd extra on an average as compared to normal test results

-- Part 2 
WITH patient_lab_summary AS (
    -- Roll up the 2.2 million labs into 1 row per patient
    SELECT 
        patient_id, 
        MAX(is_abnormal) AS had_abnormal_lab -- If they have even one 1, this returns 1
    FROM lab_results
    GROUP BY patient_id
)
SELECT 
    case when p.had_abnormal_lab = 0 then 'Normal' else 'Abnormal' end as lab_test_results,
    COUNT(o.patient_id) AS total_actual_patients,
    ROUND(AVG(o.total_charges_usd), 2) AS avg_charge_per_patient
FROM outcomes o
JOIN patient_lab_summary p
    ON o.patient_id = p.patient_id
GROUP BY p.had_abnormal_lab
order by avg_charge_per_patient desc;

-- It is found that the hospital is using DRG codes to charge the patients that's why we were having similar
-- average charges for patients having abnormal vs normal results and icu admissions vs non icu admission patients 
select 
primary_drg as DRG_code, 
count(patient_id) as total_patients,
case when icu_admission = 1 then 'Required' else 'Not Required' end as icu_admission_required,
ROUND(AVG(length_of_stay_days), 2) AS avg_length_of_stay,
round(avg(total_charges_usd), 2) as avg_flat_rate_charge,
round(sum(total_charges_usd), 2) as total_charges,
sum(in_hospital_death) as hospital_deaths, 
round(avg(icu_days), 2) as avg_icu_days
from outcomes 
group by primary_drg, icu_admission_required
order by avg_flat_rate_charge desc;

/* 
During my financial analysis, I noticed the average charges were uniformly hovering around $18,000 
regardless of the slice. By auditing my row counts, I discovered the dataset had a grain mismatch: 
outcomes were aggregated at the patient level, while diagnoses were transactional. I realized that joining 
them directly created a Cartesian product that was smearing the financial data, so I pivoted my financial analysis 
to 1-to-1 patient-level metrics to ensure accuracy.
*/

-- Q9. Insurance Disparities: How do hospital charges, mortality rates, and average Length of Stay (LOS) vary across different insurance types?
select 
insurance_type, 
count(o.patient_id) as total_patients,
round(avg(length_of_stay_days), 2) as avg_length_of_stay,
round(avg(total_charges_usd), 2) as avg_charges_per_patient,
round((avg(in_hospital_death)) * 100, 2) as avg_hospital_death
from patients p
join outcomes o
on p.patient_id = o.patient_id
group by insurance_type
order by avg_charges_per_patient desc;

/* Q.10 Resource Allocation: Which diagnostic codes generate the highest volume of lab tests per visit, and how many of those tests come back normal 
(indicating potential over-testing)? */

select
d.primary_diagnosis disease,
count(l.lab_id) as total_test_vol,
sum(1 - l.is_abnormal) as normal_results, 
round(100 * (avg(1 - l.is_abnormal)), 2) as rate_normal_results
from diagnoses d
join lab_results l 
on d.patient_id = l.patient_id
and d.visit_date = l.test_date
group by primary_diagnosis
order by  total_test_vol desc;

/*
Q11. Can we identify a specific patient profile (combining age, lifestyle, and existing comorbidities) 
that is at the absolute highest risk for mortality when admitted?
*/
select
age_group,
charlson_index as risk_score,
case when charlson_index = 0 then 'None' 
	when charlson_index between 1 and 2 then 'Mild'
    when charlson_index between 3 and 4 then 'Moderate'
    else 'High' end as severity,
smoking_status,
alcohol_use,
exercise_level,
count(o.patient_id) as total_patients,
sum(o.in_hospital_death) as hospital_death,
round(100 * (avg(o.in_hospital_death)), 2) as mortality_rate_pct
from patients p
join outcomes o
on p.patient_id = o.patient_id
group by severity, charlson_index, p.age_group, p.smoking_status, p.alcohol_use, p.exercise_level
having count(o.patient_id) > 30 and mortality_rate_pct > 0
order by mortality_rate_pct desc;

/*
10. The "Frequent Flyer" Analysis
What are the defining characteristics of patients who are readmitted to the hospital within 30 days?
	-	Is it a specific Age Group?
    - 	Is it a specific DRG code or Primary Diagnosis?
    -	Is it an Insurance Type?
*/

-- Effect of age group in readmittance
select 
age_group,
count(o.patient_id) as total_patients,
sum(o.readmitted_30d) as total_readmissions_within_30_days,
round(100 * (avg(o.readmitted_30d)), 2) as readmission_rate_pct
from patients p
join outcomes o
on p.patient_id = o.patient_id
group by age_group
order by readmission_rate_pct desc;

-- Effect of primary drg in readmittance
select 
primary_drg,
count(patient_id) as total_patients,
sum(readmitted_30d) as total_readmissions_within_30_days,
round(100 * (avg(readmitted_30d)), 2) as readmission_rate_pct
from outcomes
group by primary_drg
order by readmission_rate_pct desc;

-- Effect of insurance type in readmittance
select 
insurance_type,
count(o.patient_id) as total_patients,
sum(o.readmitted_30d) as total_readmissions_within_30_days,
round(100 * (avg(o.readmitted_30d)), 2) as readmission_rate_pct
from patients p
join outcomes o
on p.patient_id = o.patient_id
group by insurance_type
order by readmission_rate_pct desc;

-- All factors combined
select 
age_group,
insurance_type,
count(o.patient_id) as total_patients,
sum(o.readmitted_30d) as total_readmissions_within_30_days,
round(100 * (avg(o.readmitted_30d)), 2) as readmission_rate_pct
from patients p
join outcomes o
on p.patient_id = o.patient_id
group by age_group, insurance_type
having total_patients > 30
order by readmission_rate_pct desc;

-- Effect of abnormal lab results
with lab_res_summary as(
select 
	patient_id,
	sum(is_abnormal) as abnormal_results 
    from lab_results
    group by patient_id
)
select 
age_group,
abnormal_results,
count(p.patient_id) as total_patients,
sum(o.readmitted_30d) total_readmissions,
round(100 * (avg(o.readmitted_30d)), 2) as readmission_rate_pct
from patients p
join outcomes o
on p.patient_id = o.patient_id
join lab_res_summary l
on o.patient_id = l.patient_id
group by age_group, abnormal_results
having total_patients > 30
order by readmission_rate_pct desc;

/*
Insights:

Scenario 1: Effect of age in readmission
-- here as well senior age group showed highest with above 1500 readmission count as opposed to 107 for middle aged people
	-- the age heirarchy pattern followed here as well with as age increases readmission increases i.e. high correlation

scenario 2: effect of primary DRG and insurance type
-- i tested both separately and they seemed to be evenly distributed in terms of readmission rate and count
-- they are not the driving factor for readmission

scenario 3: when combined age_group with insurance type and primary drg
-- primary drg was evenly distributed in the result so left that column and again ran query with age group along side insurance
-- here as well seniority was the defining factor with insurance types evenly distributed with only minor difference in terms of readmission rate

scenario 4: combining primary diagnoses with outcome table to find any correlation with readmission
-- as primary diagnoses table has multiple entries per patient, i used second joining factor (visit_date = admission_date) 
-- only 1 or 2 patient id matched with dates as well so dropped this scenario entirely

scenario 5: Does high abnormal lab results count combined with age group affected the readmission
-- with not summarizind lab results 1 abnormal result per patient
	-- Senior age group topped the table, with abnormal results affecting the readmission rates with about 25% highest in all scenarios
		and different than other scenarios where top result had only about 15%
    
-- with mapping 1 abnormal result per patient 
	-- senior patients topped the table yet again, with 1 abrnomal result count with readmission rate of about 15%

Conclusion: Age is the single factor driving readmissions within 30 days of discharge date. 
*/

