# Customer Churn Prediction & Revenue Risk Analysis

End-to-end churn project on the IBM Telco Customer Churn dataset (7,043 customers) using Python, PostgreSQL and Power BI.

## Folder structure

```
churn_project/
├── data/        original + cleaned data, model outputs, top100_customers.csv
├── charts/      EDA and model charts (PNG)
├── notebooks/   01_cleaning.ipynb (cleaning, EDA, segmentation, ML, revenue risk)
├── sql/         churn_queries.sql
├── powerbi/     churn_dashboard.pbix
├── report/      Business_Insights_Report.pdf
└── README.md
```

## Setup

1. Install Anaconda (Python 3, pandas, numpy, scikit-learn, matplotlib, seaborn).
2. Put `WA_Fn-UseC_-Telco-Customer-Churn.csv` (Kaggle, "Telco Customer Churn") in `data/`.
3. Open `01_cleaning.ipynb` in Jupyter from the project folder and choose **Run > Run All Cells**.
   This creates the cleaned data, charts and all CSV outputs in `data/`.
4. PostgreSQL: create database `churn_db`, create table `telco`, then
   `\copy telco FROM 'data/telco_cleaned.csv' CSV HEADER`, and run `sql/churn_queries.sql`.
5. Open `churn_dashboard.pbix` in Power BI Desktop. If it asks for file locations, point the data sources at the `data/` folder.

## Method summary

- **Cleaning:** `TotalCharges` converted to numeric; 11 blank values (all tenure 0) set to 0; SeniorCitizen mapped to Yes/No; no duplicates. Added TenureGroup, MonthlyRevenueCategory, RiskGroup, ChurnFlag.
- **Segmentation:** High-Value Loyal, High-Value At-Risk, New, Long-Term, Low-Revenue.
- **Modelling:** 80/20 stratified split, preprocessing fitted on training data only, `class_weight='balanced'`; Logistic Regression and Random Forest. Identifiers, target and derived columns excluded to avoid leakage.
- **Revenue risk:** expected revenue at risk = predicted churn probability x MonthlyCharges.
- **Campaign:** top 100 active customers by expected revenue at risk, compared with 500 random draws of 100.

## Key results

| Item | Value |
|---|---|
| Overall churn rate | 26.5% |
| Best model (ROC-AUC) | Logistic Regression, 0.842 |
| Total monthly revenue | 456,116.60 |
| Monthly revenue from churned customers | 139,130.85 |
| Expected monthly revenue at risk | 114,171.10 |
| Campaign saving, top 100 vs random (monthly) | 1,254.95 vs 328.62 |

## Assumptions and limitations

- Balanced class weights inflate predicted probabilities, so absolute revenue at risk is likely overstated; use it for ranking and comparing scenarios.
- Customer-level probabilities come from a model trained on 80% of the data.
- Segment definitions use churn status, so segment churn rates are descriptive.
- The 15% campaign effect is an assumption and should be validated with an A/B test.
