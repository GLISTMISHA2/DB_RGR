-- Очистка старой структуры
DROP TABLE IF EXISTS alarm_logs, relay_logs, scenario_relays, relays, scenarios, sensor_logs, sensors, controllers CASCADE;

-- 1. Центральные контроллеры (Хабы)
CREATE TABLE controllers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- Имя контроллера должно быть уникальным
    location VARCHAR(200) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. Сетевые датчики телеметрии
CREATE TABLE sensors (
    id SERIAL PRIMARY KEY,
    controller_id INT NOT NULL REFERENCES controllers(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('temperature', 'humidity', 'co2', 'smoke', 'water_leak')), -- Допустимые типы
    unit VARCHAR(20) NOT NULL,
    critical_high FLOAT NOT NULL CHECK (critical_high > 0), -- Порог не может быть отрицательным
    created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Логи показаний датчиков (Телеметрия)
CREATE TABLE sensor_logs (
    id SERIAL PRIMARY KEY,
    sensor_id INT NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    ts TIMESTAMP DEFAULT NOW(),
    value FLOAT NOT NULL,
    is_critical BOOLEAN DEFAULT FALSE
);

-- 4. Автоматические сценарии реагирования
CREATE TABLE scenarios (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    sensor_type VARCHAR(50) NOT NULL,
    threshold_value FLOAT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- 5. Исполнительные реле (Устройства управления)
CREATE TABLE relays (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    gpio_pin VARCHAR(10) NOT NULL UNIQUE, -- Один пин — одно устройство
    controller_id INT NOT NULL REFERENCES controllers(id) ON DELETE CASCADE
);

-- 6. Связующая таблица: Сценарий -> Исполнительные реле
CREATE TABLE scenario_relays (
    scenario_id INT REFERENCES scenarios(id) ON DELETE CASCADE,
    relay_id INT REFERENCES relays(id) ON DELETE CASCADE,
    action VARCHAR(10) NOT NULL CHECK (action IN ('ON', 'OFF')),
    PRIMARY KEY (scenario_id, relay_id)
);

-- 7. Системный журнал работы реле
CREATE TABLE relay_logs (
    id SERIAL PRIMARY KEY,
    relay_id INT NOT NULL REFERENCES relays(id) ON DELETE CASCADE,
    scenario_id INT REFERENCES scenarios(id) ON DELETE SET NULL,
    sensor_log_id INT REFERENCES sensor_logs(id) ON DELETE SET NULL,
    ts TIMESTAMP DEFAULT NOW(),
    action VARCHAR(10) NOT NULL
);

-- 8. Журнал аварийных инцидентов (Алармы)
CREATE TABLE alarm_logs (
    id SERIAL PRIMARY KEY,
    sensor_id INT NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    sensor_log_id INT REFERENCES sensor_logs(id) ON DELETE CASCADE,
    ts TIMESTAMP DEFAULT NOW(),
    message TEXT NOT NULL
);

-- ============================================
-- ОПТИМИЗАЦИЯ БАЗЫ ДАННЫХ (ИНДЕКСЫ)
-- ============================================
-- Ускоряет построение графиков телеметрии по времени (самый частый поиск)
CREATE INDEX idx_sensor_logs_ts ON sensor_logs(sensor_id, ts DESC);

-- Частичный индекс: моментально находит только критические аварии
CREATE INDEX idx_sensor_logs_only_critical ON sensor_logs(is_critical) WHERE is_critical = TRUE;