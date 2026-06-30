WITH workshop_stats AS (
    SELECT
        w.workshop_id,
        w.name,
        w.type,
        w.quality,
        COUNT(wc.dwarf_id) AS num_craftsdwarves,
        SUM(wp.quantity) AS total_quantity_produced,
        SUM(p.value * wp.quantity) AS total_production_value,
        ROUND(total_quantity_produced / (MAX(wp.production_date) - MIN(wp.production_date))::INT, 2) AS daily_production_rate,
        ROUND((p.value / wp.quantity), 2) AS value_per_material_unit,
        ROUND((SUM(wm.quantity) / SUM(wp.quantity)), 2) AS material_conversion_ratio,
        ((MAX(wp.production_date) - MIN(wp.production_date))::INT - COUNT(DISTINCT wp.production_date)) AS num_days_of_downtime,
        ROUND(AVG(ds.level), 2) AS average_craftsdwarf_skill,
        ROUND(AVG(AVG(p.quality) / AVG(ds.level) WHERE ds.dwarf_id = p.created_by), 2) AS skill_quality_correlation,
    FROM
        workshops w
    LEFT JOIN
        workshop_craftsdwarves wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN
        workshop_materials wm ON w.workshop_id = wm.workshop_id
    LEFT JOIN
        workshop_products wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN
        products p ON wp.product_id = p.product_id
    LEFT JOIN
        dwarf_skills ds ON ds.dwarf_id = wc.dwarf_id
    GROUP BY
        w.workshop_id
)
SELECT
    ws.workshop_id,
    ws.name,
    ws.type,
    ws.quality,
    ws.num_craftsdwarves,
    ws.total_quantity_produced,
    ws.total_production_value,
    ws.daily_production_rate,
    ws.value_per_material_unit,
    ws.material_conversion_ratio,
    ws.num_days_of_downtime,
    ws.average_craftsdwarf_skill,
    ws.skill_quality_correlation,
    JSON_OBJECT(
        'craftsdwarf_ids', (
            SELECT JSON_ARRAYAGG(em.dwarf_id)
            FROM workshop_craftsdwarves wc
            WHERE wc.workshop_id = ws.workshop_id
        ),
        'product_ids', (
            SELECT JSON_ARRAYAGG(wp.product_id)
            FROM workshop_products wc
            WHERE wp.workshop_id = ws.workshop_id
        ),
        'material_ids', (
            SELECT JSON_ARRAYAGG(wm.material_id)
            FROM workshop_materials wm
            WHERE wm.workshop_id = ws.workshop_id
        ),
        'project_ids', (
            SELECT JSON_ARRAYAGG(p.project_id)
            FROM projects p
            WHERE p.workshop_id = ws.workshop_id
        )
    ) AS related_entities
FROM 
    workshop_stats ws
ORDER BY
    ws.daily_production_rate DESC;
