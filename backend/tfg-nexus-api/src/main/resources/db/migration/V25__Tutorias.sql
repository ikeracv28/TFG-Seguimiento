CREATE TABLE tutorias (
    id                BIGSERIAL PRIMARY KEY,
    tutor_centro_id   BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    alumno_id         BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_hora        TIMESTAMP NOT NULL,
    duracion_minutos  INT NOT NULL DEFAULT 15,
    notificado        BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tutorias_tutor  ON tutorias(tutor_centro_id);
CREATE INDEX idx_tutorias_alumno ON tutorias(alumno_id);
CREATE INDEX idx_tutorias_fecha  ON tutorias(fecha_hora);
