SELECT
    COUNT(DISTINCT c.fortress_id) AS total_trading_partners,
    SUM(tt.value) AS all_time_trade_value,
    (SUM(tt.value) WHERE tt.balance_direction = "Incoming") - (SUM(tt.value) WHERE tt.balance_direction = "Outgoing") AS all_time_trade_balance,
    JSON_OBJECT(
        "civilization_trade_data", (
            SELECT JSON_ARRAYAGG(
                de.civilization_type AS civilization_type,
                SUM(DISTINCT de.caravan_id) WHERE de.type = "Trade" AS total_caravans,
                SUM(tt.value) AS total_trade_value,
                (SUM(tt.value) WHERE tt.balance_direction = "Incoming") - (SUM(tt.value) WHERE tt.balance_direction = "Outgoing") AS trade_balance,
                (CASE WHEN SUM(de.relationship_change) < 0 THEN "Unfavorable" ELSE "Favorable") AS trade_relationship,
                CORR(total_trade_value, trade_relationship) AS diplomatic_correlation,
                JSON_ARRAYAGG(de.caravan_id)
                FROM 
                    diplomatic_events de
                LEFT JOIN
                    trade_transactions tt ON tt.caravan_id = de.caravan_id
            )
        ) AS civilization_trade_data
    ),
    JSON_OBJECT(
        "critical_import_dependencies", (
            SELECT JSON_ARRAYAGG(
                cg.material_type AS material_type,
                AVG(cg.quantity) / AVG(cg.value) AS dependency_score,
                SUM(cg.quantity) AS total_imported,
                COUNT(DISTINCT cg.name) AS import_diversity,
                JSON_ARRAYAGG(cg.original_product_id)
                FROM 
                    caravan_goods cg
                WHERE 
                    cg.type = "Incoming"
                LEFT JOIN
                    trade_transactions tt ON tt.caravan_id = de.caravan_id
            )
        ) AS resource_dependency
    ),
    JSON_OBJECT(
        "export_effectiveness", (
            SELECT JSON_ARRAYAGG(
                w.type AS workshop_type,
                p.type AS product_type,
                ROUND(wp.quantity / cg.quantity, 2) AS export_ratio, 
                JSON_ARRAYAGG(w.workshop_id) 
                FROM 
                    caravan_goods cg
                WHERE 
                    cg.type = "Outgoing"
                LEFT JOIN
                    products p ON p.material_id = cg.original_product_id
                LEFT JOIN
                    workshops w ON p.workshop_id = w.workshop_id
                LEFT JOIN
                    workshop_products wp ON wp.product_id = cg.original_product_id
            )
        ) AS export_effectiveness
    ),
    JSON_OBJECT(
        "trade_timeline", (
            SELECT JSON_ARRAYAGG(
                EXTRACT(YEAR FROM c.departure_date) AS year,
                EXTRACT(QUARTER FROM c.departure_date) AS quarter,
                SUM(tt.value) AS quarterly_value,
                (SUM(tt.value) WHERE tt.balance_direction = "Incoming") - (SUM(tt.value) WHERE tt.balance_direction = "Outgoing") AS quarterly_balance,
                COUNT(DISTINCT c.fortress_id) AS trade_diversity
                FROM 
                    caravans c
                LEFT JOIN
                    trade_transactions tt ON tt.caravan_id = c.caravan_id
                GROUP BY 
                    EXTRACT(YEAR FROM c.departure_date), EXTRACT(QUARTER FROM c.departure_date)
                ORDER BY year, quarter
            )
        ) AS trade_growth
    )
FROM 
    caravans c
LEFT JOIN
    trade_transactions tt ON tt.caravan_id = c.caravan_id;

