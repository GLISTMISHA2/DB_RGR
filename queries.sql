-- 1. [Простой SELECT] Получить полный список всех зарегистрированных датчиков
SELECT id, type, unit, critical_high FROM sensors;

-- 2. [Простой SELECT] Просмотр всех реле и их физических пинов подключения
SELECT name, gpio_pin FROM relays;

-- 3. [Фильтрация WHERE] Найти только активные работающие контроллеры
SELECT name, location FROM controllers WHERE is_active = TRUE;

-- 4. [Фильтрация WHERE] Поиск датчиков, у которых критический порог установлен выше 40 единиц
SELECT id, type, critical_high FROM sensors WHERE critical_high > 40.0;

-- 5. [Соединение JOIN] Вывод датчиков с указанием имен и локаций их хабов
SELECT s.id as sensor_id, s.type, c.name as controller_name, c.location 
FROM sensors s
JOIN controllers c ON s.controller_id = c.id;

-- 6. [Агрегация GROUP BY] Подсчет количества датчиков каждого типа в системе
SELECT type, COUNT(*) as total_sensors 
FROM sensors 
GROUP BY type;

-- 7. [Условие HAVING] Поиск типов датчиков, средний критический порог которых превышает 30
SELECT type, AVG(critical_high) as avg_threshold 
FROM sensors 
GROUP BY type 
HAVING AVG(critical_high) > 30.0;

-- 8. [Сортировка и Лимит LIMIT] Вывод 3 самых последних записей телеметрии
SELECT ts, sensor_id, value FROM sensor_logs 
ORDER BY ts DESC 
LIMIT 3;

-- 9. [Многотабличный JOIN] Сводный отчет: Сценарий + Какими реле управляет + Действие
SELECT sc.name as scenario, r.name as target_relay, sr.action 
FROM scenarios sc
JOIN scenario_relays sr ON sc.id = sr.scenario_id
JOIN relays r ON sr.relay_id = r.id;

-- 10. [Сложный подзапрос CTE / WITH] Нахождение датчиков, у которых порог выше среднего по системе
WITH average_threshold AS (
    SELECT AVG(critical_high) as system_avg FROM sensors
)
SELECT id, type, critical_high 
FROM sensors, average_threshold 
WHERE critical_high > system_avg;


-- 11. [Простой SELECT] Получить полный список зарегистрированных сценариев автоматизации
SELECT id, name, sensor_type FROM scenarios;

-- 12. [Простой SELECT] Просмотр всех логов критических аварий в системе (реестр инцидентов)
SELECT id, ts, message FROM alarm_logs;

-- 13. [Фильтрация WHERE] Найти все логи телеметрии, которые были отмечены системой как критические
SELECT id, ts, sensor_id, value FROM sensor_logs WHERE is_critical = TRUE;

-- 14. [Фильтрация WHERE] Поиск реле, которые подключены к пинам ввода-вывода выше 17-го
SELECT id, name, gpio_pin FROM relays WHERE gpio_pin > 'GPIO_17';

-- 15. [Соединение JOIN] Вывод истории работы реле с указанием их понятных названий и портов
SELECT rl.id as log_id, rl.ts, r.name, r.gpio_pin 
FROM relay_logs rl
JOIN relays r ON rl.relay_id = r.id;

-- 16. [Агрегация GROUP BY] Подсчет количества логов телеметрии, отправленных каждым конкретным датчиком
SELECT sensor_id, COUNT(*) as total_logs 
FROM sensor_logs 
GROUP BY sensor_id;

-- 17. [Условие HAVING] Найти датчики, у которых среднее отправленное значение телеметрии превысило 40 единиц
SELECT sensor_id, AVG(value) as avg_recorded_value 
FROM sensor_logs 
GROUP BY sensor_id 
HAVING AVG(value) > 40.0;

-- 18. [Сортировка и Лимит LIMIT] Вывод 3 самых старых (первых) записей контроллеров в системе
SELECT id, name, location FROM controllers 
ORDER BY id ASC 
LIMIT 3;

-- 19. [Многотабличный JOIN] Полный сводный отчет: какой датчик (его тип) привязан к какому контроллеру и где он расположен
SELECT c.name as controller, c.location, s.id as sensor_id, s.type as sensor_type
FROM controllers c
JOIN sensors s ON s.controller_id = c.id;

-- 20. [Сложный подзапрос CTE / WITH] Найти логи датчиков, у которых текущие показания выше среднего значения логов по этому типу датчика
-- (Исправлено: переписали логику CTE на вычисление средней телеметрии, так как в scenarios нет поля critical_high)
WITH type_averages AS (
    SELECT s.type as s_type, AVG(sl.value) as avg_val
    FROM sensor_logs sl
    JOIN sensors s ON sl.sensor_id = s.id
    GROUP BY s.type
)
SELECT sl.ts, s.id as sensor_id, s.type, sl.value, ROUND(ta.avg_val::numeric, 2) as type_average_value
FROM sensor_logs sl
JOIN sensors s ON sl.sensor_id = s.id
JOIN type_averages ta ON s.type = ta.s_type
WHERE sl.value > ta.avg_val;