# Expense Tracker (Oracle APEX)

## 📌 Overview
Expense Tracker is an Oracle APEX application designed to manage **Expenses, Income, and Deposits**.  
It provides dynamic daily and monthly reports, cumulative totals, and pivot views for deeper financial insights.  
The app is lightweight, demo‑ready, and includes schema setup with seed data for immediate testing.

## ✨ Features
- Track transactions by category and type (Expense, Income, Deposit).
- Daily and monthly breakdowns with cumulative totals.
- Interactive Report Pivot for dynamic columns (e.g., 2026-Jan, 2026-Feb).
- Date range filters with sensible defaults (current day/month).
- Exportable SQL scripts for schema, reports, and seed data.

## 🛠 Setup Instructions
1. **Import the APEX app**  
   - Upload `apex_app/expense_tracker_app.sql` into Oracle APEX.  

2. **Run schema setup**  
   - Execute `sql/schema_setup.sql` in your Oracle XE/19c database.  
   - This creates tables, transaction types, categories, and sample data.  

3. **Reports**  
   - Use `sql/daily_category_report.sql` and `sql/monthly_category_report.sql` for custom reporting.  
   - Pivot views can be configured directly in APEX Interactive Reports.  

## 📂 Repository Structure
expense-tracker-apex/
├── apex_app/                  # APEX app export
├── sql/                       # Schema + report queries
├── docs/                      # Documentation + screenshots
└── README.md                  # Project overview


## 📸 Demo
Screenshots of the APEX pages are available in `docs/screenshots/`.

## ⚙️ Requirements
- Oracle APEX 20.2+
- Oracle XE 19c
