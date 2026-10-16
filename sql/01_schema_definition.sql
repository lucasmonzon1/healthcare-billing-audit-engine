-- Database Schema for Healthcare Claims & Settlement Engine
CREATE TABLE dim_providers (
    provider_id STRING,
    provider_name STRING,
    provider_type STRING,
    tax_id STRING,
    onboarding_date DATE
);

CREATE TABLE fact_claims_invoiced (
    claim_id STRING,
    provider_id STRING,
    invoice_number STRING,
    invoice_date DATE,
    service_category STRING,
    billed_amount_usd FLOAT64
);

CREATE TABLE fact_audit_findings (
    audit_id STRING,
    claim_id STRING,
    audit_type STRING,
    discrepancy_code STRING,
    audit_deduction_amount_usd FLOAT64
);

CREATE TABLE fact_credit_notes_settlement (
    settlement_id STRING,
    claim_id STRING,
    credit_note_number STRING,
    credit_note_amount_usd FLOAT64,
    settlement_status STRING,
    payment_order_issued INT64
);
