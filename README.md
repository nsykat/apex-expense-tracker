# Expense Tracker (Oracle APEX)

## Overview
Expense Tracker is an Oracle APEX application to manage **Expenses, Income, and Deposits**.  
It includes dynamic reports for daily and monthly tracking, with cumulative totals and pivot views.

## Features
- Track transactions by category and type (Expense, Income, Deposit).
- Date range filters (defaults to current day/month if blank).
- Daily and Monthly reports with cumulative totals.
- Interactive Report Pivot for dynamic columns (e.g., 2026-Jan, 2026-Feb).
- Exportable SQL scripts for schema and reports.

## Setup
1. Import `Application/expense_tracker_app.sql` into Oracle APEX.
2. Run `sql/schema_setup.sql` in your Oracle XE/19c database.

## Requirements
- Oracle APEX 20.2+
- Oracle XE 19c

## Demo
Screenshots are available in `docs/screenshots/`.
