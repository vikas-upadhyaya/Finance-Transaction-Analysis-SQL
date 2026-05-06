CREATE TABLE customers (
    customer_id         VARCHAR(10)     PRIMARY KEY,
    customer_name       VARCHAR(100)    NOT NULL,
    age                 INT             NOT NULL,
    city                VARCHAR(50)     NOT NULL,
    account_type        VARCHAR(20)     NOT NULL,
    branch              VARCHAR(50)     NOT NULL,
    account_open_date   DATE            NOT NULL,
    opening_balance     NUMERIC(12, 2)  NOT NULL
);

CREATE TABLE transactions (
    transaction_id      VARCHAR(12)     PRIMARY KEY,
    customer_id         VARCHAR(10)     NOT NULL,
    transaction_date    DATE            NOT NULL,
    transaction_type    VARCHAR(10)     NOT NULL,
    category            VARCHAR(50)     NOT NULL,
    amount              NUMERIC(12, 2)  NOT NULL,
    balance_after       NUMERIC(12, 2)  NOT NULL,
    branch              VARCHAR(50)     NOT NULL,
    account_type        VARCHAR(20)     NOT NULL,
    day_of_week         VARCHAR(10)     NOT NULL,
    month               INT             NOT NULL,
    year                INT             NOT NULL,
    quarter             VARCHAR(5)      NOT NULL,

    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

COPY customers 
FROM 'C:\customers.csv' 
DELIMITER ',' CSV HEADER;

COPY transactions 
FROM 'C:\transactions.csv' 
DELIMITER ',' CSV HEADER;


-- Q1. Month-over-Month Transaction Volume Growth Rate by Account Type 

WITH monthly_volume AS (
    SELECT
        account_type,
        year,
        month,
        COUNT(transaction_id)       AS total_transactions,
        ROUND(SUM(amount)::NUMERIC, 2) AS total_amount
    FROM transactions
    GROUP BY account_type, year, month
),
mom_growth AS (
    SELECT
        account_type,
        year,
        month,
        total_transactions,
        total_amount,
        LAG(total_amount) OVER (
            PARTITION BY account_type
            ORDER BY year, month
        ) AS prev_month_amount
    FROM monthly_volume
)
SELECT
    account_type,
    year,
    month,
    total_transactions,
    total_amount,
    prev_month_amount,
    ROUND(
        (total_amount - prev_month_amount) * 100.0 / prev_month_amount, 2
    ) AS mom_growth_pct
FROM mom_growth
WHERE prev_month_amount IS NOT NULL
ORDER BY account_type, year, month;


-- Q2. Top 5 Spending Categories per Account Type

WITH category_spend AS (
    SELECT
        account_type,
        category,
        ROUND(SUM(amount)::NUMERIC, 2)  AS total_spend,
        COUNT(transaction_id)            AS txn_count,
        ROUND(AVG(amount)::NUMERIC, 2)  AS avg_spend
    FROM transactions
    WHERE transaction_type = 'Debit'
    GROUP BY account_type, category
),
ranked AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY account_type
            ORDER BY total_spend DESC
        ) AS spend_rank
    FROM category_spend
)
SELECT
    account_type,
    category,
    total_spend,
    txn_count,
    avg_spend,
    spend_rank
FROM ranked
WHERE spend_rank <= 5
ORDER BY account_type, spend_rank;


-- Q3. High-Value Customer Segmentation (Top 10%)

WITH customer_metrics AS (
    SELECT
        t.customer_id,
        c.customer_name,
        c.account_type,
        c.branch,
        ROUND(AVG(t.balance_after)::NUMERIC, 2)  AS avg_balance,
        COUNT(t.transaction_id)                    AS txn_frequency,
        ROUND(SUM(CASE WHEN t.transaction_type = 'Credit'
                       THEN t.amount ELSE 0 END)::NUMERIC, 2) AS total_inflow,
        ROUND(SUM(CASE WHEN t.transaction_type = 'Debit'
                       THEN t.amount ELSE 0 END)::NUMERIC, 2) AS total_outflow
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    GROUP BY t.customer_id, c.customer_name, c.account_type, c.branch
),
percentile_rank AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY avg_balance DESC) AS balance_decile
    FROM customer_metrics
)
SELECT
    customer_id,
    customer_name,
    account_type,
    branch,
    avg_balance,
    txn_frequency,
    total_inflow,
    total_outflow,
    'High Value' AS customer_segment
FROM percentile_rank
WHERE balance_decile = 1
ORDER BY avg_balance DESC;


-- Q4. Dormant Account Detection (No Transaction in 60+ Days)

WITH last_transaction AS (
    SELECT
        t.customer_id,
        c.customer_name,
        c.account_type,
        c.branch,
        MAX(t.transaction_date) AS last_txn_date,
        CURRENT_DATE - MAX(t.transaction_date) AS days_since_last_txn
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    GROUP BY t.customer_id, c.customer_name, c.account_type, c.branch
)
SELECT
    customer_id,
    customer_name,
    account_type,
    branch,
    last_txn_date,
    days_since_last_txn,
    CASE
        WHEN days_since_last_txn >= 60 THEN 'Dormant'
        WHEN days_since_last_txn >= 30 THEN 'Inactive'
        ELSE 'Active'
    END AS account_status
FROM last_transaction
ORDER BY days_since_last_txn DESC;


-- Q5. Suspicious Transaction Detection (Fraud Flagging)

WITH customer_avg AS (
    SELECT
        customer_id,
        ROUND(AVG(amount)::NUMERIC, 2) AS avg_debit_amount
    FROM transactions
    WHERE transaction_type = 'Debit'
    GROUP BY customer_id
),
flagged_transactions AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        c.customer_name,
        c.branch,
        t.transaction_date,
        t.category,
        t.amount,
        ca.avg_debit_amount,
        ROUND((t.amount / ca.avg_debit_amount)::NUMERIC, 2) AS times_above_avg
    FROM transactions t
    JOIN customers c   ON t.customer_id  = c.customer_id
    JOIN customer_avg ca ON t.customer_id = ca.customer_id
    WHERE t.transaction_type = 'Debit'
      AND t.amount > ca.avg_debit_amount * 3
)
SELECT *,
    'Suspicious' AS flag
FROM flagged_transactions
ORDER BY times_above_avg DESC;


-- Q6. At-Risk Customers (Balance Below ₹1000 More Than 3 Times)

WITH low_balance_events AS (
    SELECT
        t.customer_id,
        c.customer_name,
        c.account_type,
        c.branch,
        t.quarter,
        t.year,
        COUNT(*) AS times_below_1000
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    WHERE t.balance_after < 1000
    GROUP BY
        t.customer_id, c.customer_name,
        c.account_type, c.branch,
        t.quarter, t.year
)
SELECT
    customer_id,
    customer_name,
    account_type,
    branch,
    year,
    quarter,
    times_below_1000,
    'At Risk' AS risk_flag
FROM low_balance_events
WHERE times_below_1000 > 3
ORDER BY times_below_1000 DESC;


-- Q7. Branch Performance — Weekday vs Weekend

WITH branch_performance AS (
    SELECT
        branch,
        CASE
            WHEN day_of_week IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END                                     AS day_type,
        COUNT(transaction_id)                   AS total_transactions,
        ROUND(SUM(amount)::NUMERIC, 2)          AS total_value,
        ROUND(AVG(amount)::NUMERIC, 2)          AS avg_txn_value
    FROM transactions
    GROUP BY branch, day_type
),
pivoted AS (
    SELECT
        branch,
        MAX(CASE WHEN day_type = 'Weekday'
                 THEN total_value END)          AS weekday_value,
        MAX(CASE WHEN day_type = 'Weekend'
                 THEN total_value END)          AS weekend_value,
        MAX(CASE WHEN day_type = 'Weekday'
                 THEN total_transactions END)   AS weekday_txns,
        MAX(CASE WHEN day_type = 'Weekend'
                 THEN total_transactions END)   AS weekend_txns
    FROM branch_performance
    GROUP BY branch
)
SELECT
    branch,
    weekday_value,
    weekend_value,
    weekday_txns,
    weekend_txns,
    ROUND((weekend_value * 100.0 / weekday_value)::NUMERIC, 2) AS weekend_to_weekday_ratio,
    CASE
        WHEN weekend_value * 100.0 / weekday_value < 30
        THEN 'Underperforming on Weekends'
        ELSE 'Balanced'
    END AS operational_insight
FROM pivoted
ORDER BY weekend_to_weekday_ratio ASC;


