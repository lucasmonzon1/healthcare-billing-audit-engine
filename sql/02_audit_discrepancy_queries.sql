-- Query 1: Executive Settlement & Leakage Audit Summary
WITH ClaimsAgg AS (
    SELECT 
        COUNT(DISTINCT claim_id) AS total_claims,
        ROUND(SUM(billed_amount_usd), 2) AS gross_invoiced_usd
    FROM `claims_audit.fact_claims_invoiced`
),
AuditAgg AS (
    SELECT 
        COUNT(DISTINCT claim_id) AS flagged_claims,
        ROUND(SUM(audit_deduction_amount_usd), 2) AS total_audit_debits_usd
    FROM `claims_audit.fact_audit_findings`
)
SELECT 
    c.total_claims,
    a.flagged_claims,
    c.gross_invoiced_usd,
    a.total_audit_debits_usd,
    ROUND(c.gross_invoiced_usd - a.total_audit_debits_usd, 2) AS net_approved_disbursement_usd,
    ROUND((a.total_audit_debits_usd / c.gross_invoiced_usd) * 100, 2) AS leakage_prevention_pct
FROM ClaimsAgg c
CROSS JOIN AuditAgg a;

-- Query 2: Provider Variance Risk Ranking (Top Discrepancy Outliers)
SELECT 
    p.provider_name,
    p.provider_type,
    COUNT(c.claim_id) AS claims_submitted,
    ROUND(SUM(c.billed_amount_usd), 2) AS total_billed_usd,
    ROUND(COALESCE(SUM(a.audit_deduction_amount_usd), 0), 2) AS total_deductions_usd,
    ROUND(
        (COALESCE(SUM(a.audit_deduction_amount_usd), 0) / SUM(c.billed_amount_usd)) * 100, 2
    ) AS variance_rate_pct,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(a.audit_deduction_amount_usd), 0) DESC) AS risk_rank
FROM `claims_audit.dim_providers` p
JOIN `claims_audit.fact_claims_invoiced` c ON p.provider_id = c.provider_id
LEFT JOIN `claims_audit.fact_audit_findings` a ON c.claim_id = a.claim_id
GROUP BY p.provider_name, p.provider_type
ORDER BY risk_rank;

-- Query 3: Capital at Risk & Frozen Payment Orders (Dispute Resolution Pipeline)
SELECT 
    c.invoice_number,
    p.provider_name,
    c.billed_amount_usd,
    a.audit_type,
    a.discrepancy_code,
    a.audit_deduction_amount_usd AS required_credit_note_usd,
    COALESCE(cn.credit_note_amount_usd, 0.0) AS received_credit_note_usd,
    ROUND(a.audit_deduction_amount_usd - COALESCE(cn.credit_note_amount_usd, 0.0), 2) AS capital_at_risk_usd,
    CASE 
        WHEN cn.settlement_status = 'MATCHED_AND_RESOLVED' THEN 'Ready for Payment Order (OP)'
        WHEN cn.settlement_status = 'PENDING_CREDIT_NOTE' THEN 'Payment Frozen - Pending Credit Note'
        WHEN cn.settlement_status = 'DISPUTED' THEN 'Dispute Escalated - Under Review'
        ELSE 'Pending Review'
    END AS dispute_workflow_status
FROM `claims_audit.fact_claims_invoiced` c
JOIN `claims_audit.dim_providers` p ON c.provider_id = p.provider_id
JOIN `claims_audit.fact_audit_findings` a ON c.claim_id = a.claim_id
LEFT JOIN `claims_audit.fact_credit_notes_settlement` cn ON c.claim_id = cn.claim_id
WHERE COALESCE(cn.settlement_status, 'PENDING') != 'MATCHED_AND_RESOLVED'
ORDER BY capital_at_risk_usd DESC;