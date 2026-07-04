WITH squad_stats AS (
    SELECT
        ms.squad_id,
        ms.name AS squad_name,
        ms.formation_type,
        (d.name WHERE ms.leader_id = d.dwarf_id) AS leader_name,
        (COUNT(DISTINCT sb.report_id)) AS total_battles,
        (COUNT(DISTINCT sb.report_id) WHERE sb.outcome = "Victory") AS victories,
        ROUND(AVG(sb.casualties), 2) AS casualty_rate,
        ROUND(AVG(sb.casualties) / AVG(sb.enemy_casualties), 2) AS casualty_exchange_ratio,
        COUNT(DISTINCT sm.dwarf_id WHERE sm.exit_date IS NULL) AS current_members,
        COUNT(DISTINCT sm.dwarf_id) AS total_members_ever,
        ROUND(current_members / total_members_ever, 2) AS retention_rate,
        (AVG(e.quality)) AS avg_equipment_quality,
        (COUNT(DISTINCT st.schedule_id)) AS total_training_sessions,
        (AVG(st.effectiveness)) AS avg_training_effectiveness,
        (AVG(ds.experience) WHERE ds.date = sb.date) AS avg_combat_skill_improvement
    FROM
        military_squads ms
    LEFT JOIN
        squad_members sm ON sm.squad_id = ms.squad_id
    LEFT JOIN
        squad_battles sb ON sb.squad_id = ms.squad_id
    LEFT JOIN
        squad_equipment se ON se.squad_id = ms.squad_id
    LEFT JOIN
        equipment e ON se.equipment_id = e.equipment_id
    LEFT JOIN
        squad_training st ON st.squad_id = ms.squad_id
    LEFT JOIN
        dwarf_skills ds ON ds.dwarf_id = sm.dwarf_id

)
SELECT 
    ss.squad_id,
    ss.squad_name,
    ss.formation_type,
    ss.leader_name,
    ss.total_battles,
    ss.victories,
    ROUND(ss.victories / ss.total_battles, 2) AS victory_percentage,
    ss.casualty_rate,
    ss.casualty_exchange_ratio,
    ss.current_members,
    ss.total_members_ever,
    ss.retention_rate,
    ss.avg_equipment_quality,
    ss.total_training_sessions,
    ss.avg_training_effectiveness,
    CORR(ss.victories, ss.total_training_sessions) AS training_battle_correlation,
    ss.avg_combat_skill_improvement,
    ROUND(((ss.victory_percentage * 0.2 + ss.casualty_exchange_ratio * 0.2 + ss.avg_equipment_quality * 0.2 + ss.avg_training_effectiveness * 0.2 + ss.avg_combat_skill_improvement * 0.2)/ 100), 2) AS overall_effectiveness_score,
    JSON_OBJECT(
        'member_ids', (
            SELECT JSON_ARRAYAGG(sm.dwarf_id)
            FROM squad_members sm
            WHERE ss.squad_id = sm.squad_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(se.equipment_id)
            FROM squad_equipment se
            WHERE ss.squad_id = se.squad_id
        ),
        'battle_report_ids', (
            SELECT JSON_ARRAYAGG(sb.report_id)
            FROM squad_battles sb
            WHERE ss.squad_id = sb.squad_id
        ),
        'training_ids', (
            SELECT JSON_ARRAYAGG(st.schedule_id)
            FROM squad_training st
            WHERE ss.squad_id = st.squad_id
        )
    ) AS related_entities
FROM 
    squad_stats ss
GROUP BY
    ss.squad_id
ORDER BY
    ss.overall_effectiveness_score DESC;

