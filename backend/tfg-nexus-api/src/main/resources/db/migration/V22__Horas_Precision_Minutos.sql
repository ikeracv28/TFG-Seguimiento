-- Amplía la precisión de horas_realizadas de NUMERIC(5,1) a NUMERIC(6,3)
-- para permitir registrar minutos exactos (ej. 7h 13min = 7.217h).
-- La conversión es sin pérdida: NUMERIC(5,1) ya cabe en NUMERIC(6,3).
ALTER TABLE seguimientos
  ALTER COLUMN horas_realizadas TYPE NUMERIC(6,3)
    USING horas_realizadas::NUMERIC(6,3);
