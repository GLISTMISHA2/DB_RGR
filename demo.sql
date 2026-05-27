-- Эмуляция ЧП: датчик дыма (ID = 1) фиксирует значение 85.0 ppm (при норме до 50)
INSERT INTO sensor_logs (sensor_id, value) VALUES (1, 85.0);

-- 1. Проверяем, сработал ли триггер и появилась ли запись об аварии
\echo '=== РЕЕСТР АВАРИЙНЫХ ИНЦИДЕНТОВ (ALARM_LOGS) ==='
SELECT ts, message FROM alarm_logs;

-- 2. Проверяем, включились ли реле автоматической вытяжки и сирены
\echo '=== АВТОМАТИЧЕСКИЙ ЗАПУСК ИСПОЛНИТЕЛЬНЫХ УСТРОЙСТВ ==='
SELECT rl.ts, r.name as device_name, rl.action as state, sc.name as trigger_reason
FROM relay_logs rl
JOIN relays r ON rl.relay_id = r.id
JOIN scenarios sc ON rl.scenario_id = sc.id;

-- 3. Проверка работы хранимой функции-счетчика аварий
\echo '=== СЧЕТЧИК АКТИВНЫХ ТРЕВОГ ЗА ПОСЛЕДНИЙ ЧАС ==='
SELECT get_active_alarms_count() as active_alarms;