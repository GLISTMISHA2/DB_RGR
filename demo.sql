
INSERT INTO sensor_logs (sensor_id, value) VALUES (1, 85.0);

\echo '=== РЕЕСТР АВАРИЙНЫХ ИНЦИДЕНТОВ (ALARM_LOGS) ==='
SELECT ts, message FROM alarm_logs;

\echo '=== АВТОМАТИЧЕСКИЙ ЗАПУСК ИСПОЛНИТЕЛЬНЫХ УСТРОЙСТВ ==='
SELECT rl.ts, r.name as device_name, rl.action as state, sc.name as trigger_reason
FROM relay_logs rl
JOIN relays r ON rl.relay_id = r.id
JOIN scenarios sc ON rl.scenario_id = sc.id;

\echo '=== СЧЕТЧИК АКТИВНЫХ ТРЕВОГ ЗА ПОСЛЕДНИЙ ЧАС ==='
SELECT get_active_alarms_count() as active_alarms;
