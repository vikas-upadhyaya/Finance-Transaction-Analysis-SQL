# Finance-Transaction-Analysis-SQL

## 📌 Project Overview
Analyzed 100,000+ banking transactions across 500 customers 
and 10 branches to uncover revenue trends, detect suspicious 
activity, and identify at-risk customer segments using 
advanced SQL techniques.

## 🎯 Business Questions Answered
1. What is the month-over-month transaction volume 
   growth rate by account type?
2. Which spending categories drive the highest outflow 
   per account type?
3. Who are the top 10% high-value customers by 
   average balance?
4. Which accounts have gone dormant (60+ days 
   inactive)?
5. Which transactions are potentially suspicious 
   (3x above customer's own average)?
6. Which customers are at risk (balance dropped 
   below ₹1000 more than 3 times)?
7. How does branch performance compare between 
   weekdays and weekends?

## 🛠️ Tools & Concepts Used
- **Database:** PostgreSQL
- **Tool:** pgAdmin 4
- **Concepts:** CTEs, Window Functions (LAG, RANK, 
  NTILE), Joins, Aggregations, CASE Statements, 
  Date Functions, Subqueries

## 📁 Dataset Overview
| Table | Rows | Description |
|---|---|---|
| customers | 500 | Customer demographics & account info |
| transactions | 100,000 | Banking transactions (2023–2024) |

## 🔍 Key Findings

### 📈 Q1 — Month-over-Month Growth
- **Salary accounts** recorded the highest single-month growth of **+27.87%** in March 2023
- **Current accounts** followed closely with a **+26.34%** spike in May 2024
- Transaction volumes showed consistent fluctuation across all account types with no sustained downtrend

### 💳 Q2 — Top Spending Categories
- **Savings accounts** drove the highest overall outflow — Groceries (₹1.61Cr), Entertainment (₹1.60Cr), and Shopping (₹1.60Cr) were top categories
- **Current accounts** spent most on Dining (₹82.7L), Utilities (₹82.5L), and Fuel (₹81.9L)
- **Salary accounts** had Utilities (₹68.6L) and Fuel (₹68.1L) as their largest expense heads

### 👥 Q3 — High-Value Customer Segmentation
- **50 customers** (top 10%) were identified as High Value based on average account balance
- **Top customer: Divya Hegde** (CUST0404, Koramangala) with an average balance of **₹12,08,897**
- Current account holders dominated the high-value segment, accounting for 7 out of top 10 customers

### 😴 Q4 — Dormant Account Detection
- All **500 customers** were classified as **Dormant** since the dataset covers transactions through December 2024 (500+ days ago)
- Last recorded transactions were in December 2024, with **Kiran Rao (CUST0128)** having the oldest last transaction (Dec 6, 2024)
- This finding highlights the importance of recency tracking in customer retention strategies

### ⚠️ Q5 — Suspicious Transaction Detection
- **1,173 transactions** were flagged as potentially suspicious (amount more than 3x the customer's own average debit)
- **Most extreme case: Gaurav Hegde** — an EMI payment of ₹34,671 that was **6.55x above his own average**, flagged as highest-risk
- EMI, Fuel, and Entertainment were the most common categories in flagged transactions

### 🔴 Q6 — At-Risk Customers
- **10 unique customers** were identified as at-risk across multiple quarters
- **Harini Joshi (CUST0383)** was the most financially stressed — balance dropped below ₹1,000 **7 times in Q4 2024** alone
- **Riya Bhat (CUST0088)** appeared in 4 different quarters as at-risk, indicating a persistent financial vulnerability pattern

### 🏢 Q7 — Branch Performance (Weekday vs Weekend)
- All 10 branches maintained a **Balanced** operational status with weekend volumes consistently at ~38–44% of weekday volumes
- **Electronic City** had the **lowest weekend-to-weekday ratio (38.85%)** — indicating lower weekend footfall relative to weekday activity
- **MG Road** showed the **strongest weekend engagement (43.65%)** among all branches
- **Yelahanka** processed the **highest overall weekday transaction value (₹1.01Cr)**, making it the most operationally active branch


## 📂 Project Structure
├── datasets/    → Raw CSV files
├── queries/     → Individual SQL files per question
├── results/     → Query output CSVs
└── schema/      → Table creation script

