-- Очистка старых функций
DROP TRIGGER IF EXISTS trg_process_telemetry ON sensor_logs;
DROP FUNCTION IF EXISTS process_sensor_telemetry();
DROP FUNCTION IF EXISTS get_active_alarms_count();

-- 1. Хранимая функция-утилита (считает аварии)
CREATE OR REPLACE FUNCTION get_active_alarms_count()
RETURNS INT AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM alarm_logs WHERE ts >= NOW() - INTERVAL '1 hour');
END;
$$ LANGUAGE plpgsql;

-- 2. Исправленная триггерная функция (работает ПОСЛЕ вставки)
CREATE OR REPLACE FUNCTION process_sensor_telemetry()
RETURNS TRIGGER AS $$
DECLARE
    v_critical_high FLOAT;
    v_sensor_type VARCHAR(50);
    v_scenario_id INT;
    v_relay_id INT;
    v_action VARCHAR(10);
BEGIN
    -- Получаем пороговые значения датчика
    SELECT critical_high, type INTO v_critical_high, v_sensor_type
    FROM sensors WHERE id = NEW.sensor_id;

    -- Если значение превысило критический порог
    IF NEW.value >= v_critical_high THEN
        -- 1. Обновляем статус критичности в уже созданной записи
        UPDATE sensor_logs SET is_critical = TRUE WHERE id = NEW.id;

        -- 2. Пишем в лог экстренных тревог
        INSERT INTO alarm_logs (sensor_id, sensor_log_id, message)
        VALUES (NEW.sensor_id, NEW.id, '🚨 КРИТИЧЕСКИЙ СБОЙ! Превышен порог по метрике ' || v_sensor_type || ': ' || NEW.value);

        -- 3. Ищем активный сценарий под этот тип датчика
        SELECT id INTO v_scenario_id FROM scenarios 
        WHERE sensor_type = v_sensor_type AND is_active = TRUE LIMIT 1;

        -- 4. Автоматически включаем привязанные реле
        IF v_scenario_id IS NOT NULL THEN
            FOR v_relay_id, v_action IN 
                SELECT relay_id, action FROM scenario_relays WHERE scenario_id = v_scenario_id
            LOOP
                INSERT INTO relay_logs (relay_id, scenario_id, sensor_log_id, action)
                VALUES (v_relay_id, v_scenario_id, NEW.id, v_action);
            END LOOP;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Навешиваем триггер со статусом AFTER (ПОСЛЕ вставки строки)
CREATE TRIGGER trg_process_telemetry
AFTER INSERT ON sensor_logs
FOR EACH ROW
EXECUTE FUNCTION process_sensor_telemetry();