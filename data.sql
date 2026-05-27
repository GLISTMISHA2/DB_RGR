TRUNCATE TABLE controllers, sensors, sensor_logs, scenarios, relays, scenario_relays, relay_logs, alarm_logs CASCADE;

-- 1. Контроллеры
INSERT INTO controllers (id, name, location) VALUES 
(1, 'Серверный Хаб', 'Серверная комната'),
(2, 'Контроллер Кухни', 'Кухня-Студия');

-- 2. Датчики (привязаны к простым ID контроллеров)
INSERT INTO sensors (id, controller_id, type, unit, critical_high) VALUES 
(1, 2, 'smoke', 'ppm', 50.0),       -- Датчик дыма на кухне
(2, 1, 'temperature', '°C', 35.0),  -- Датчик температуры в серверной
(3, 2, 'water_leak', 'bool', 1.0);  -- Датчик протечки на кухне

-- 3. Исполнительные устройства (Реле)
INSERT INTO relays (id, name, gpio_pin, controller_id) VALUES 
(1, 'Вытяжная вентиляция', 'GPIO_17', 2),
(2, 'Звуковая сирена', 'GPIO_18', 2),
(3, 'Кондиционер охлаждения', 'GPIO_19', 1);

-- 4. Сценарии автоматизации
INSERT INTO scenarios (id, name, sensor_type, threshold_value) VALUES 
(1, 'Ликвидация задымления', 'smoke', 50.0),
(2, 'Охлаждение оборудования', 'temperature', 35.0);

-- 5. Связи Сценарий -> Реле
INSERT INTO scenario_relays (scenario_id, relay_id, action) VALUES 
(1, 1, 'ON'),  -- При дыме включить вентиляцию
(1, 2, 'ON'),  -- При дыме включить сирену
(2, 3, 'ON');  -- При жаре врубить кондей

-- 6. Нормальная (стабильная) история телеметрии для наполнения базы (без триггерных аварий)
INSERT INTO sensor_logs (sensor_id, value, ts) VALUES 
(1, 12.5, NOW() - INTERVAL '5 minutes'),
(1, 14.1, NOW() - INTERVAL '4 minutes'),
(2, 22.4, NOW() - INTERVAL '5 minutes'),
(2, 23.1, NOW() - INTERVAL '3 minutes'),
(3, 0.0,  NOW() - INTERVAL '10 minutes');