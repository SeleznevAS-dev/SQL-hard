-- 1
SELECT
    name
FROM
    Squads
WHERE
    leader_id IS NULL;

-- 2
SELECT
    name,
    age
FROM
    Dwarves
WHERE
    age >= 150 AND profession = 'Warrior';

-- 3
SELECT
    D.name,
    D.age,
    D.profession,
    I.name
FROM
    Dwarves D
JOIN
    Items I
ON
    D.dwarf_id = I.owner_id
GROUP BY
    D.dwarf_id, D.name, D.profession
HAVING
    I.type = "weapon";

-- 4
SELECT
    D.name,
    D.age,
    T.status,
    COUNT(*) AS TasksCount
FROM
    Dwarves D
JOIN
    Tasks T
ON
    D.dwarf_id = T.assigned_to
GROUP BY
    D.name, T.status;

-- 5
SELECT
    T.name,
    T.status
FROM
    Tasks T
JOIN
    Dwarves D
ON
    D.dwarf_id = T.assigned_to
JOIN
    Squads S
ON
    D.squad_id = S.squad_id
HAVING
    S.name = 'Guardians';

-- 6
SELECT
    D.name,
    D.age,
    D.profession,
    (SELECT name FROM Dwarves WHERE dwarf_id = R.related_to) AS Relative,
    R.relationship
FROM
    Dwarves D
JOIN
    Relationships R
ON
    D.dwarf_id = R.dwarf_id
WHERE
    R.relationship IN ('Родитель', 'Ребенок')
GROUP BY D.name, R.relationship;