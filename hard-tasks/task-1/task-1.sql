SELECT
    e.expedition_id,
    e.destination,
    e.status,
    (ROUND((SELECT COUNT(*) 
        FROM expedition_members em
        WHERE em.survived = TRUE AND
        em.expedition_id = e.expedition_id) / (
        CAST(COUNT(*) AS DECIMAL(10,2))
            AS all_members_decimal
            FROM expedition_members em
            WHERE em.expedition_id = e.expedition_id)
    ), 2) AS survival_rate,
    SUM(SELECT ea.value
        FROM expedition_artifacts ea
        WHERE ea.expedition_id = e.expedition_id
    ) AS artifacts_value,
    (SELECT COUNT(*)
        FROM expedition_sites es
        WHERE es.expedition_id = e.expedition_id
    ) AS discovered_sites,
    (ROUND((SELECT COUNT(*) 
        FROM expedition_creatures ec
        WHERE ec.outcome = "Win" AND
        ec.expedition_id = e.expedition_id) / (
        CAST(COUNT(*) AS DECIMAL(10,2))
            AS expedition_creatures_decimal
            FROM expedition_creatures ec
            WHERE ec.outcome = "Lose" AND
            ec.expedition_id = e.expedition_id)
    ), 2) AS encounter_success_rate,
    (SELECT COUNT(*)
        FROM dwarf_skills ds
        WHERE date BETWEEN e.departure_date AND e.return_date
    ) AS skill_improvement,
    DATEDIFF(day, e.departure_date, e.return_date
    ) AS expedition_duration,
    JSON_OBJECT(
        'member_ids', (
            SELECT JSON_ARRAYAGG(em.dwarf_id)
            FROM expedition_members
            WHERE em.expedition_id = e.expedition_id
        ),
        'artifact_ids', (
            SELECT JSON_ARRAYAGG(ea.artifact_id)
            FROM expedition_artifacts ea
            WHERE ea.expedition_id = e.expedition_id
        ),
        'site_ids', (
            SELECT JSON_ARRAYAGG(es.site_id)
            FROM expedition_sites es
            WHERE es.expedition_id = e.expedition_id
        )
    ) AS related_entities
FROM
    expeditions e