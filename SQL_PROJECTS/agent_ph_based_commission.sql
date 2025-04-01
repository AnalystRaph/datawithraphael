SELECT
    *,
    ROUND(
        (
            CASE
                WHEN ph_colour = 'Green' THEN collections * 0.095
                WHEN ph_colour = 'Yellow' THEN collections * 0.048
                WHEN ph_colour = 'Red' THEN collections * 0.014
                ELSE 0
            END
        ),
        0
    ) AS commission
FROM
    (
        WITH
            AgentLoanData AS (
                SELECT DISTINCT
                    ld.loan_id AS loan_account_id,
                    ld.customer_id,
                    CASE
                        WHEN CURRENT_DATE - DATE(soi.sale_date_utc) <= 7 THEN 'Quality'
                        WHEN ld.loan_type = 'paygo' AND ld.unpaid_percent < 30 THEN 'Quality'
                        WHEN ld.loan_type = 'arrears' AND ld.days_past_due < 7 THEN 'Quality'
                        WHEN ld.loan_type IS NULL AND ld.days_past_due < 7 THEN 'Quality'
                        ELSE 'Non-Quality'
                    END AS quality_status,
                    CASE
                        WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                        ELSE ref.referrer_id
                    END AS sales_agent_id,
                    agent.agent_name,
                    mapping.agent_manager_name,
                    agent_activity.activity AS agent_activity,
                    agent_activity.primary_phone_number AS agent_phone_number,
                    agent.zone
                FROM
                    CoreData.LoanDetails ld
                    LEFT JOIN CoreData.CustomerDetails cust ON ld.customer_id = cust.customer_id
                    LEFT JOIN SalesData.SalesOrderItems soi ON ld.loan_id = soi.loan_id
                    LEFT JOIN SensitiveData.CustomerSensitiveInfo csi ON csi.customer_id = soi.customer_id
                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = ld.customer_id
                    LEFT JOIN AnalystInputs.AgentMapping mapping ON mapping.sales_agent_id = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                    LEFT JOIN (
                        SELECT DISTINCT
                            lic.contractor_id,
                            con.name || ' ' || con.surname AS agent_name,
                            SPLIT_PART(StockPointUtils.GetStockPointZone(lic.hub_id), '~', 2) AS zone
                        FROM
                            OperationalData.ContractorLicenses lic
                            LEFT JOIN OperationalData.Contractors con ON con.contractor_id = lic.contractor_id
                        WHERE
                            lic.contractor_id ILIKE '%%ke%%'
                            AND lic.purpose NOT IN ('fundi', 'maintenance_fundi', 'loan_officer')
                    ) agent ON agent.contractor_id = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                    LEFT JOIN (
                        SELECT DISTINCT
                            sale_owner,
                            MAX(sale_date) OVER (PARTITION BY sale_owner) AS last_sale_date,
                            CASE
                                WHEN MAX(sale_date) OVER (PARTITION BY sale_owner) >= CURRENT_DATE - 60 THEN 'active'
                                WHEN MAX(sale_date) OVER (PARTITION BY sale_owner) < CURRENT_DATE - 60 THEN 'inactive'
                                ELSE 'null'
                            END AS activity,
                            con.contractor_number,
                            pd1.phone_number AS primary_phone_number,
                            pd2.phone_number AS payments_phone_number
                        FROM
                            (
                                SELECT
                                    DATE(so.sale_date_utc) AS sale_date,
                                    CASE
                                        WHEN ref.referrer_type = 'Contractor' THEN ref.referrer_id
                                        ELSE cust.application_contractor_id
                                    END AS sale_owner
                                FROM
                                    SalesData.SalesOrderItems so
                                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = so.customer_id
                                    LEFT JOIN CoreData.CustomerDetails cust ON cust.customer_id = so.customer_id
                                WHERE
                                    so.product_category = 'ReadyPay'
                                    AND so.country = 'KE'
                                    AND so.currency = 'KES'
                            ) AS sales
                            LEFT JOIN OperationalData.Contractors con ON con.contractor_id = sales.sale_owner
                            LEFT JOIN SensitiveData.PhoneDecoder pd1 ON pd1.encrypted_phone = con.encrypted_phone
                            LEFT JOIN SensitiveData.PhoneDecoder pd2 ON pd2.encrypted_phone = con.encrypted_payment_phone
                    ) AS agent_activity ON agent_activity.sale_owner = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                WHERE
                    ld.loan_id ILIKE '%%ke%%'
                    AND soi.product_category = 'ReadyPay'
                    AND ld.loan_status NOT IN ('paid_off', 'canceled')
                    AND soi.account_type <> 'CASH'
                    AND ld.loan_type <> 'cash'
                    AND ld.detailed_status <> 'potentially_paid_off'
                UNION
                SELECT DISTINCT
                    lrr.new_loan_id AS loan_account_id,
                    lrr.customer_id,
                    CASE
                        WHEN CURRENT_DATE - DATE(soi.sale_date_utc) <= 7 THEN 'Quality'
                        WHEN ld.loan_type = 'paygo' AND ld.unpaid_percent < 30 THEN 'Quality'
                        WHEN ld.loan_type = 'arrears' AND ld.days_past_due < 7 THEN 'Quality'
                        WHEN ld.loan_type IS NULL AND ld.days_past_due < 7 THEN 'Quality'
                        ELSE 'Non-Quality'
                    END AS quality_status,
                    CASE
                        WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                        ELSE ref.referrer_id
                    END AS sales_agent_id,
                    agent.agent_name,
                    mapping.agent_manager_name,
                    agent_activity.activity AS agent_activity,
                    agent_activity.primary_phone_number AS agent_phone_number,
                    agent.zone
                FROM
                    CoreData.LoanDetails ld
                    LEFT JOIN CoreData.LoanRescheduleRequests lrr ON lrr.customer_id = ld.customer_id AND lrr.new_loan_id = ld.loan_id
                    LEFT JOIN CoreData.CustomerDetails cust ON cust.customer_id = ld.customer_id
                    LEFT JOIN SalesData.SalesOrderItems soi ON soi.customer_id = ld.customer_id
                    LEFT JOIN SensitiveData.CustomerSensitiveInfo csi ON csi.customer_id = soi.customer_id
                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = ld.customer_id
                    LEFT JOIN AnalystInputs.AgentMapping mapping ON mapping.sales_agent_id = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                    LEFT JOIN (
                        SELECT DISTINCT
                            lic.contractor_id,
                            con.name || ' ' || con.surname AS agent_name,
                            SPLIT_PART(StockPointUtils.GetStockPointZone(lic.hub_id), '~', 2) AS zone
                        FROM
                            OperationalData.ContractorLicenses lic
                            LEFT JOIN OperationalData.Contractors con ON con.contractor_id = lic.contractor_id
                        WHERE
                            lic.contractor_id ILIKE '%%ke%%'
                            AND lic.purpose NOT IN ('fundi', 'maintenance_fundi', 'loan_officer')
                    ) agent ON agent.contractor_id = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                    LEFT JOIN (
                        SELECT DISTINCT
                            sale_owner,
                            MAX(sale_date) OVER (PARTITION BY sale_owner) AS last_sale_date,
                            CASE
                                WHEN MAX(sale_date) OVER (PARTITION BY sale_owner) >= CURRENT_DATE - 60 THEN 'active'
                                WHEN MAX(sale_date) OVER (PARTITION BY sale_owner) < CURRENT_DATE - 60 THEN 'inactive'
                                ELSE 'null'
                            END AS activity,
                            con.contractor_number,
                            pd1.phone_number AS primary_phone_number,
                            pd2.phone_number AS payments_phone_number
                        FROM
                            (
                                SELECT
                                    DATE(so.sale_date_utc) AS sale_date,
                                    CASE
                                        WHEN ref.referrer_type = 'Contractor' THEN ref.referrer_id
                                        ELSE cust.application_contractor_id
                                    END AS sale_owner
                                FROM
                                    SalesData.SalesOrderItems so
                                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = so.customer_id
                                    LEFT JOIN CoreData.CustomerDetails cust ON cust.customer_id = so.customer_id
                                WHERE
                                    so.product_category = 'ReadyPay'
                                    AND so.country = 'KE'
                                    AND so.currency = 'KES'
                            ) AS sales
                            LEFT JOIN OperationalData.Contractors con ON con.contractor_id = sales.sale_owner
                            LEFT JOIN SensitiveData.PhoneDecoder pd1 ON pd1.encrypted_phone = con.encrypted_phone
                            LEFT JOIN SensitiveData.PhoneDecoder pd2 ON pd2.encrypted_phone = con.encrypted_payment_phone
                    ) AS agent_activity ON agent_activity.sale_owner = (
                        CASE
                            WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                            ELSE ref.referrer_id
                        END
                    )
                WHERE
                    lrr.new_loan_id ILIKE '%%ke%%'
                    AND soi.product_category = 'ReadyPay'
                    AND ld.loan_status NOT IN ('paid_off', 'canceled')
            ),
            AgentCollections AS (
                SELECT DISTINCT
                    CASE
                        WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                        ELSE ref.referrer_id
                    END AS agent_id,
                    SUM(pay.amount / 100) AS collections
                FROM
                    CoreData.PaymentBookings pay
                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = pay.customer_id
                    LEFT JOIN CoreData.CustomerDetails cust ON cust.customer_id = pay.customer_id
                WHERE
                    pay.customer_id ILIKE '%ke%'
                    AND pay.payment_source != 'PaymentDetailsCompensation'
                    AND pay.transaction_type = 'PaymentChargeTransaction'
                    AND pay.payment_date BETWEEN '2025-03-24' AND '2025-03-30'
                GROUP BY 1
                UNION ALL
                SELECT
                    CASE
                        WHEN ref.referrer_type = 'Customer' THEN cust.application_contractor_id
                        ELSE ref.referrer_id
                    END AS agent_id,
                    SUM(alt.amount / 100) AS collections
                FROM
                    CoreData.LoanTransactions alt
                    LEFT JOIN CoreData.Referrals ref ON ref.customer_id = alt.customer_id
                    LEFT JOIN CoreData.CustomerDetails cust ON cust.customer_id = alt.customer_id
                WHERE
                    alt.transaction_type = 'Loan Payment'
                    AND alt.customer_id LIKE '%ke%'
                    AND alt.transaction_date_utc BETWEEN '2025-03-24' AND '2025-03-30'
                GROUP BY 1
            )
        SELECT
            ald.sales_agent_id,
            ald.agent_name,
            ald.agent_phone_number,
            ald.agent_activity,
            ald.zone,
            COUNT(ald.customer_id) AS total_customers,
            ROUND(
                CASE
                    WHEN COUNT(ald.customer_id) > 0 THEN CAST(SUM(CASE WHEN ald.quality_status = 'Quality' THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(ald.customer_id) AS FLOAT) * 100
                    ELSE 0
                END,
                2
            ) AS quality_percentage,
            CASE
                WHEN ROUND(CASE WHEN COUNT(ald.customer_id) > 0 THEN CAST(SUM(CASE WHEN ald.quality_status = 'Quality' THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(ald.customer_id) AS FLOAT) * 100 ELSE 0 END, 2) >= 85 THEN 'Green'
                WHEN ROUND(CASE WHEN COUNT(ald.customer_id) > 0 THEN CAST(SUM(CASE WHEN ald.quality_status = 'Quality' THEN 1 ELSE 0 END) AS FLOAT) / CAST(COUNT(ald.customer_id) AS FLOAT) * 100 ELSE 0 END, 2) >= 65 THEN 'Yellow'
                ELSE 'Red'
            END AS ph_colour,
            ac.collections
        FROM
            AgentLoanData ald
            LEFT JOIN AgentCollections ac ON ac.agent_id = ald.sales_agent_id
        WHERE
            ald.agent_activity = 'active'
            AND ald.zone <> 'Telesales'
            AND ac.collections IS NOT NULL
        GROUP BY
            ald.sales_agent_id,
            ald.agent_name,
            ald.agent_phone_number,
            ald.agent_activity,
            ald.zone,
            ac.collections
        ORDER BY
            ac.collections DESC
    ) AS subquery
WHERE commission >= 50
ORDER BY commission DESC;
