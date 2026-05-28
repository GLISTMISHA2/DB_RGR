
SELECT id, type, unit, critical_high FROM sensors;


SELECT name, gpio_pin FROM relays;

SELECT name, location FROM controllers WHERE is_active = TRUE;

SELECT id, type, critical_high FROM sensors WHERE critical_high > 40.0;

SELECT s.id as sensor_id, s.type, c.name as controller_name, c.location 
FROM sensors s
JOIN controllers c ON s.controller_id = c.id;

SELECT type, COUNT(*) as total_sensors 
FROM sensors 
GROUP BY type;

SELECT type, AVG(critical_high) as avg_threshold 
FROM sensors 
GROUP BY type 
HAVING AVG(critical_high) > 30.0;

SELECT ts, sensor_id, value FROM sensor_logs 
ORDER BY ts DESC 
LIMIT 3;

SELECT sc.name as scenario, r.name as target_relay, sr.action 
FROM scenarios sc
JOIN scenario_relays sr ON sc.id = sr.scenario_id
JOIN relays r ON sr.relay_id = r.id;

WITH average_threshold AS (
    SELECT AVG(critical_high) as system_avg FROM sensors
)
SELECT id, type, critical_high 
FROM sensors, average_threshold 
WHERE critical_high > system_avg;

SELECT id, name, sensor_type FROM scenarios;

SELECT id, ts, message FROM alarm_logs;

SELECT id, ts, sensor_id, value FROM sensor_logs WHERE is_critical = TRUE;

SELECT id, name, gpio_pin FROM relays WHERE gpio_pin > 'GPIO_17';

SELECT rl.id as log_id, rl.ts, r.name, r.gpio_pin 
FROM relay_logs rl
JOIN relays r ON rl.relay_id = r.id;

SELECT sensor_id, COUNT(*) as total_logs 
FROM sensor_logs 
GROUP BY sensor_id;

SELECT sensor_id, AVG(value) as avg_recorded_value 
FROM sensor_logs 
GROUP BY sensor_id 
HAVING AVG(value) > 40.0;

SELECT id, name, location FROM controllers 
ORDER BY id ASC 
LIMIT 3;

SELECT c.name as controller, c.location, s.id as sensor_id, s.type as sensor_type
FROM controllers c
JOIN sensors s ON s.controller_id = c.id;

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
