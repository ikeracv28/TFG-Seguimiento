-- Añade tipo de registro: DIARIO (defecto) o SEMANAL
ALTER TABLE seguimientos
    ADD COLUMN tipo VARCHAR(10) NOT NULL DEFAULT 'DIARIO';
