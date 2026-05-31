-- V24: Permite eliminar usuarios desactivados ajustando FK constraints hacia usuarios.
-- Regla: solo se puede eliminar si activo = false (validado en servicio).
-- - Borrar alumno:        CASCADE -> practicas -> seguimientos/incidencias/mensajes/ausencias (V20)
-- - Borrar tutor/admin:   SET NULL en campos de tutor, sin borrar prácticas ajenas

-- 1. usuario_roles: CASCADE
ALTER TABLE usuario_roles
    DROP CONSTRAINT IF EXISTS fk_usuario_roles_usuario,
    ADD CONSTRAINT fk_usuario_roles_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- 2. notificaciones: CASCADE
ALTER TABLE notificaciones
    DROP CONSTRAINT IF EXISTS fk_notificacion_usuario,
    ADD CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- 3. practicas.alumno_id: CASCADE (borra prácticas y toda la cadena del V20)
ALTER TABLE practicas
    DROP CONSTRAINT IF EXISTS fk_practica_alumno,
    ADD CONSTRAINT fk_practica_alumno
        FOREIGN KEY (alumno_id) REFERENCES usuarios(id) ON DELETE CASCADE;

-- 4. practicas.tutor_centro_id: hacer nullable + SET NULL
ALTER TABLE practicas ALTER COLUMN tutor_centro_id DROP NOT NULL;
ALTER TABLE practicas
    DROP CONSTRAINT IF EXISTS fk_practica_tutor_centro,
    ADD CONSTRAINT fk_practica_tutor_centro
        FOREIGN KEY (tutor_centro_id) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 5. practicas.tutor_empresa_id: hacer nullable + SET NULL
ALTER TABLE practicas ALTER COLUMN tutor_empresa_id DROP NOT NULL;
ALTER TABLE practicas
    DROP CONSTRAINT IF EXISTS fk_practica_tutor_empresa,
    ADD CONSTRAINT fk_practica_tutor_empresa
        FOREIGN KEY (tutor_empresa_id) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 6. seguimientos.validado_por: SET NULL (ya nullable)
ALTER TABLE seguimientos
    DROP CONSTRAINT IF EXISTS fk_seguimiento_validador,
    ADD CONSTRAINT fk_seguimiento_validador
        FOREIGN KEY (validado_por) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 7. incidencias.creada_por: hacer nullable + SET NULL
ALTER TABLE incidencias ALTER COLUMN creada_por DROP NOT NULL;
ALTER TABLE incidencias
    DROP CONSTRAINT IF EXISTS fk_incidencia_creador,
    ADD CONSTRAINT fk_incidencia_creador
        FOREIGN KEY (creada_por) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 8. incidencias.resuelta_por: SET NULL (ya nullable)
ALTER TABLE incidencias
    DROP CONSTRAINT IF EXISTS fk_incidencia_resolutor,
    ADD CONSTRAINT fk_incidencia_resolutor
        FOREIGN KEY (resuelta_por) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 9. mensajes.remitente_id (renombrado desde emisor_id en V11): hacer nullable + SET NULL
ALTER TABLE mensajes ALTER COLUMN remitente_id DROP NOT NULL;
ALTER TABLE mensajes
    DROP CONSTRAINT IF EXISTS fk_mensaje_emisor,
    ADD CONSTRAINT fk_mensaje_emisor
        FOREIGN KEY (remitente_id) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 10 & 11. ausencias: constraints sin nombre — los localizamos por pg_constraint
DO $$
DECLARE v_c TEXT;
BEGIN
    SELECT conname INTO v_c FROM pg_constraint
    WHERE conrelid = 'ausencias'::regclass
      AND confrelid = 'usuarios'::regclass
      AND contype = 'f'
      AND conkey = ARRAY[(
          SELECT attnum FROM pg_attribute
          WHERE attrelid = 'ausencias'::regclass AND attname = 'registrada_por_id'
      )]::smallint[];
    IF v_c IS NOT NULL THEN
        EXECUTE 'ALTER TABLE ausencias DROP CONSTRAINT ' || quote_ident(v_c);
    END IF;
END $$;
ALTER TABLE ausencias ALTER COLUMN registrada_por_id DROP NOT NULL;
ALTER TABLE ausencias
    ADD CONSTRAINT fk_ausencia_registrada_por
        FOREIGN KEY (registrada_por_id) REFERENCES usuarios(id) ON DELETE SET NULL;

DO $$
DECLARE v_c TEXT;
BEGIN
    SELECT conname INTO v_c FROM pg_constraint
    WHERE conrelid = 'ausencias'::regclass
      AND confrelid = 'usuarios'::regclass
      AND contype = 'f'
      AND conkey = ARRAY[(
          SELECT attnum FROM pg_attribute
          WHERE attrelid = 'ausencias'::regclass AND attname = 'revisada_por_id'
      )]::smallint[];
    IF v_c IS NOT NULL THEN
        EXECUTE 'ALTER TABLE ausencias DROP CONSTRAINT ' || quote_ident(v_c);
    END IF;
END $$;
ALTER TABLE ausencias
    ADD CONSTRAINT fk_ausencia_revisada_por
        FOREIGN KEY (revisada_por_id) REFERENCES usuarios(id) ON DELETE SET NULL;

-- 12. evaluacion_final.tutor_empresa_id: hacer nullable + SET NULL
DO $$
DECLARE v_c TEXT;
BEGIN
    SELECT conname INTO v_c FROM pg_constraint
    WHERE conrelid = 'evaluacion_final'::regclass
      AND confrelid = 'usuarios'::regclass
      AND contype = 'f';
    IF v_c IS NOT NULL THEN
        EXECUTE 'ALTER TABLE evaluacion_final DROP CONSTRAINT ' || quote_ident(v_c);
    END IF;
END $$;
ALTER TABLE evaluacion_final ALTER COLUMN tutor_empresa_id DROP NOT NULL;
ALTER TABLE evaluacion_final
    ADD CONSTRAINT fk_evaluacion_tutor_empresa
        FOREIGN KEY (tutor_empresa_id) REFERENCES usuarios(id) ON DELETE SET NULL;
