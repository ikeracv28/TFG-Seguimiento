-- V14: Evaluación final del alumno por el tutor del centro
-- Una práctica solo puede tener una evaluación final (UNIQUE en practica_id)

CREATE TABLE IF NOT EXISTS evaluacion_final (
    id               BIGSERIAL PRIMARY KEY,
    practica_id      BIGINT        NOT NULL UNIQUE REFERENCES practicas(id) ON DELETE CASCADE,
    tutor_centro_id  BIGINT        NOT NULL REFERENCES usuarios(id),
    nota             DECIMAL(4,2)  NOT NULL CHECK (nota >= 0 AND nota <= 10),
    comentario       TEXT,
    fecha_evaluacion TIMESTAMP     NOT NULL DEFAULT NOW()
);
