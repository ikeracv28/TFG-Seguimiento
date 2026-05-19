-- Permite registrar medias horas (ej. 7.5h) en los partes de prácticas.
ALTER TABLE seguimientos
    ALTER COLUMN horas_realizadas TYPE NUMERIC(5,1) USING horas_realizadas::NUMERIC(5,1);
