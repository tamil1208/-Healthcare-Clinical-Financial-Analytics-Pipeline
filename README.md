
# 🏥 Healthcare Clinical & Financial Analytics Pipeline
**An End-to-End ETL, Database Engineering, and Business Intelligence Architecture**

## 📌 Executive Summary
This project architects a complete data pipeline to analyze clinical outcomes, operational efficiency, and financial billing models for a synthetic healthcare network. By migrating over 3 million records from raw CSVs into a structured MySQL relational database, and ultimately into a dynamic Power BI Star Schema, this project uncovers the true drivers of hospital readmissions and demystifies flat-rate DRG billing structures. 

**Tech Stack:** Python (Pandas, NumPy, SQLAlchemy) | MySQL | Power BI | DAX

## 🏗️ Architecture & Data Engineering
The raw dataset consisted of highly denormalized, multi-grain clinical records (demographics, lab results, medications, and hospital outcomes). 

**The ETL Process:**
1. **Extraction & Transformation (Python/Pandas):** * Engineered new features including a validated Charlson Comorbidity Index mapping and age-group clustering.
   * Normalized pipe-delimited `secondary_diagnoses` strings into a strict 1-to-Many relational bridging table using `.explode()`.
   * Preserved structural nulls (e.g., `days_to_readmission`) to protect downstream analytical integrity.
2. **Database Loading (MySQL):** * Designed a relational schema to handle 1-to-1 patient outcomes alongside 1-to-Many transactional lab results. 
   * Executed a memory-efficient bulk insert of 2.2 million lab records utilizing optimized chunking (`chunksize=50000`).
3. **Data Modeling (SQL Views -> Power BI):**
   * Constructed a strict Star Schema utilizing SQL Views as a semantic layer. 
   * Pre-aggregated the 2.2 million-row lab results table using Common Table Expressions (CTEs) within the SQL View to prevent Cartesian product explosions when joining to patient financial outcomes. 

## 🔍 Exploratory Data Analysis & Key Insights

During the SQL EDA phase, I tested multiple clinical hypotheses by isolating variables to find the root causes of hospital inefficiencies. 

### Insight 1: Demystifying the "Cartesian Smear" & DRG Billing
* **The Anomaly:** Initial queries joining transaction-level diagnoses to patient-level outcomes showed evenly distributed hospital charges (~$18,000) across all diseases, with zero cost variance between ICU and Non-ICU patients. 
* **The Investigation:** Row-count audits revealed a grain mismatch causing hospital bills to duplicate across every historical disease a patient possessed. 
* **The Conclusion:** After isolating the 1-to-1 primary outcome records, the data definitively proved the hospital utilizes **Diagnosis-Related Group (DRG) flat-rate billing** rather than Fee-For-Service. 

### Insight 2: Uninsured Mortality Disparities
When slicing financial outcomes by `insurance_type`, the data revealed a stark clinical reality:
* **Uninsured Patients** received the highest "Self-Pay Discounts" (lowest overall bills), but suffered the **longest average hospital stays (5.29 days)** and the **highest in-hospital mortality rate (1.53%)**. 
* **Conclusion:** Lack of insurance drives delayed care, resulting in patients presenting at the emergency room with much higher acuity.

### Insight 3: The 25% Readmission Spike
I ran distinct scenarios to determine the root cause of 30-day hospital readmissions.
* **Scenario A (Demographics):** Age proved to be the baseline gravity. Readmissions strictly followed the age hierarchy (Senior > Middle Age > Adult). 
* **Scenario B (Clinical Complexity):** When grouping the data purely by a binary "Abnormal Lab" flag, readmission rates hovered at a flat 15%.
* **Scenario C (Combined Synthesis):** When counting the *volume* of abnormal lab tests per patient and combining it with the Senior age bracket, a distinct cohort emerged with a **26.3% readmission rate**.
* **Conclusion:** While age is the baseline driver, Age combined with high clinical complexity (volume of failed tests) is the ultimate predictor of readmission. 

## 📊 Power BI Dashboard
***1. Financial & Operational Overview:***
<img width="1280" height="724" alt="Financial   Operational Overview" src="https://github.com/user-attachments/assets/8b6c39fa-513e-444b-af32-0d1db78d4e45" />

***2. Clinical Risk & Readmission Dynamics:***
<img width="1276" height="719" alt="Clinical Risk   Readmission Dynamics" src="https://github.com/user-attachments/assets/bef29f6b-1132-49ef-b618-9e1aa614a3e1" />


## 🚀 How to Run Locally
1. Clone this repository.
2. **Download the dataset [here](https://www.kaggle.com/datasets/sauryayan/synthetic-healthcare-records-and-financial-outcomes/data) and extract the CSVs into the patients/data/ folder.**
3. Ensure MySQL Server is running locally on port 3306.
4. Configure your environment variables for `DB_USER_PROJECT` and `DB_PASS_PROJECT`.
5. Run the Jupyter Notebook `patient_analytics.ipynb` to execute the ETL pipeline.
6. Open the `Healthcare_Analytics.pbix` file to interact with the dashboard.
