-- 1
SELECT * FROM Dwarves
RIGHT JOIN Squads ON Dwarves.squad_id = Squads.squad_id
WHERE Dwarves.squad_id IS NOT NULL;

-- 2
SELECT * FROM Dwarves
WHERE (profession="miner") AND (squad_id IS NULL);

-- 3
SELECT * FROM Tasks
WHERE (priority=(SELECT MAX(priority) FROM Tasks)) AND (status="pending");

-- 4
SELECT owner_id, COUNT(*) AS Количество_предметов
FROM Items
WHERE owner_id IS NOT NULL
GROUP BY owner_id;

-- 5
SELECT squad_id, COUNT(Dwarves.dwarf_id) AS Количество_гномов
FROM Squads
INNER JOIN Dwarves ON Squads.squad_id = Dwarves.squad_id
GROUP BY squad_id;

-- 6
SELECT Dwarves.profession, COUNT(*) AS Незавершенные_задачи
FROM Dwarves
INNER JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
WHERE Tasks.status IN ('pending', 'in_progress')
GROUP BY Dwarves.profession
HAVING COUNT(*) >= ALL (
    SELECT COUNT(*)
    FROM Dwarves
    INNER JOIN Tasks ON Dwarves.dwarf_id = Tasks.assigned_to
    WHERE Tasks.status IN ('pending', 'in_progress')
    GROUP BY Dwarves.profession
);

-- 7
SELECT Items.type, AVG(Dwarves.age) AS Средний_возраст_владельцев
FROM Items
LEFT JOIN Dwarves ON Items.owner_id = Dwarves.dwarf_id
GROUP BY Items.type;

-- 8
SELECT * FROM Dwarves
LEFT JOIN Items ON Dwarves.dwarf_id = Items.owner_id
WHERE Dwarves.age > (SELECT AVG(age) FROM Dwarves)
AND Items.owner_id IS NULL;