-- Consolidated Analytical View
CREATE OR REPLACE VIEW `claims_audit.v_claims_master_reporting` AS
SELECT 
    c.claim_id,
    c.invoice_number,
    c.invoice_date,
    c.service_category,
    c.billed_amount_usd,
    p.provider_name,
    p.provider_type,
    a.audit_id,
    a.audit_type,
    a.discrepancy_code,
    COALESCE(a.audit_deduction_amount_usd, 0.0) AS audit_deduction_amount_usd,
    cn.credit_note_number,
    COALESCE(cn.credit_note_amount_usd, 0.0) AS credit_note_amount_usd,
    COALESCE(cn.settlement_status, 'CLEAN_SETTLEMENT') AS settlement_status,
    COALESCE(cn.payment_order_issued, 1) AS payment_order_issued,
    ROUND(c.billed_amount_usd - COALESCE(a.audit_deduction_amount_usd, 0.0), 2) AS net_approved_payout_usd,
    ROUND(COALESCE(a.audit_deduction_amount_usd, 0.0) - COALESCE(cn.credit_note_amount_usd, 0.0), 2) AS open_capital_at_risk_usd
FROM `claims_audit.fact_claims_invoiced` c
JOIN `claims_audit.dim_providers` p ON c.provider_id = p.provider_id
LEFT JOIN `claims_audit.fact_audit_findings` a ON c.claim_id = a.claim_id
LEFT JOIN `claims_audit.fact_credit_notes_settlement` cn ON c.claim_id = cn.claim_id;