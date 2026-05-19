-- Fix FK constraints para permitir eliminación en cascada de prácticas BORRADOR.
-- Las FK originales (V1) se crearon sin ON DELETE CASCADE; las corregimos aquí.

ALTER TABLE seguimientos
    DROP CONSTRAINT IF EXISTS fk_seguimiento_practica,
    ADD CONSTRAINT fk_seguimiento_practica
        FOREIGN KEY (practica_id) REFERENCES practicas(id) ON DELETE CASCADE;

ALTER TABLE incidencias
    DROP CONSTRAINT IF EXISTS fk_incidencia_practica,
    ADD CONSTRAINT fk_incidencia_practica
        FOREIGN KEY (practica_id) REFERENCES practicas(id) ON DELETE CASCADE;

ALTER TABLE mensajes
    DROP CONSTRAINT IF EXISTS fk_mensaje_practica,
    ADD CONSTRAINT fk_mensaje_practica
        FOREIGN KEY (practica_id) REFERENCES practicas(id) ON DELETE CASCADE;

-- ausencias no tiene nombre de constraint explícito en V8; usamos DO block para
-- eliminar la FK existente antes de añadir la nueva.
DO $$
DECLARE
    v_constraint text;
BEGIN
    SELECT conname INTO v_constraint
    FROM pg_constraint
    WHERE conrelid = 'ausencias'::regclass
      AND confrelid = 'practicas'::regclass
      AND contype = 'f'
    LIMIT 1;

    IF v_constraint IS NOT NULL THEN
        EXECUTE 'ALTER TABLE ausencias DROP CONSTRAINT ' || quote_ident(v_constraint);
    END IF;
END $$;

ALTER TABLE ausencias
    ADD CONSTRAINT fk_ausencia_practica
        FOREIGN KEY (practica_id) REFERENCES practicas(id) ON DELETE CASCADE;

-- notificaciones: no tienen FK directa a practicas, no se toca.
