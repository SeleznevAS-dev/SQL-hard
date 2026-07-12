WITH attacks_data AS (
    SELECT
        COUNT(DISTINCT ca.attack_id) AS total_recorded_attacks,
        COUNT(DISTINCT ca.creature_id) AS unique_attackers,
        COUNT(DISTINCT ca.attack_id) WHERE ca.outcome = "Win" AS winned_attacks,
        COUNT(DISTINCT ca.attack_id) WHERE ca.outcome = "Lose" AS losed_attacks,
    FROM
        creature_attacks ca
),
threats_data AS (
    SELECT
        c.creature_id,
        c.type AS creature_type,
        c.threat_level,
        MAX(cs.date) AS last_sighting_date,
        ct.distance_to_fortress AS territory_proximity,
        COUNT(DISTINCT c.creature_id) WHERE c.active IS TRUE AS estimated_numbers
    FROM
        creatures c
    JOIN
        creature_sightings cs
    ON
        c.creature_id = cs.creature_id
    JOIN
        creature_territories ct
    ON
        c.creature_id = ct.creature_id
    GROUP BY
        c.creature_id
)
vulnerability_data AS (
    SELECT
        l.zone_id,
        l.name AS zone_name,
        COUNT(l.location_id) WHERE ca.outcome = "Lose" AS historical_breaches,
        l.fortification_level,
        AVG(ca.military_response_time_minutes) AS military_response_time,
    FROM
        locations l
    JOIN
        creature_attacks ca
    ON
        l.location_id = ca.location_id
    GROUP BY
        l.zone_id
)
security_data AS (
    SELECT
        EXTRACT(YEAR FROM ca.date) AS year,
        ROUND(ca.enemy_casualties / ca.defense_structures_used, 2) AS defense_success_rate,
        COUNT(DISTINCT ca.attack_id) AS total_attacks,
        ca.casualties,
    FROM
        creature_attacks ca
    GROUP BY
        EXTRACT(YEAR FROM ca.date)
)
SELECT
    ad.total_recorded_attacks,
    ad.unique_attackers,
    ROUND(ad.winned_attacks / ad.total_recorded_attacks) AS overall_defense_success_rate,
    JSON_OBJECT(
        "threat_assessment", (
            SELECT td.threat_level WHERE td.last_sighting_date = MAX(td.last_sighting_date) AS current_threat_level,
            SELECT JSON_ARRAYAGG(
                "creature_type", td.creature_type,
                "threat_level", td.threat_level,
                "last_sighting_date", td.last_sighting_date,
                "territory_proximity", td.territory_proximity,
                "estimated_numbers", td.estimated_numbers,
                "creature_ids", (
                    SELECT JSON_ARRAYAGG(ca.creature_id)
                    FROM creature_attacks ca
                    WHERE ca.creature_id = td.creature_id
                )
            )
            FROM threats_data td
        ),
        "vulnerability_analysis", (
            SELECT JSON_ARRAYAGG(
                "zone_id", vd.zone_id,
                "zone_name", vd.zone_name,
                "historical_breaches", vd.historical_breaches,
                "fortification_level", vd.fortification_level,
                "military_response_time", vd.military_response_time
            )
            FROM vulnerability_data vd
        ),
        "security_evolution", (
            SELECT JSON_ARRAYAGG(
                "year", sd.yead,
                "defense_success_rate", sd.defense_success_rate,
                "total_attacks", sd.total_attacks,
                "casualties", sd.casualties,
            )
            FROM security_data sd
        )
    ) AS security_analysis,
FROM attacks_data ad
