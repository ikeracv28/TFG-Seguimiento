-- V15: Rediseño de evaluacion_final — cuestionario por el tutor de empresa
-- Se elimina la tabla anterior (vacía en dev) y se recrea con criterios detallados

DROP TABLE IF EXISTS evaluacion_final;

CREATE TABLE evaluacion_final (
    id                   BIGSERIAL    PRIMARY KEY,
    practica_id          BIGINT       NOT NULL UNIQUE REFERENCES practicas(id) ON DELETE CASCADE,
    tutor_empresa_id     BIGINT       NOT NULL REFERENCES usuarios(id),

    -- Criterios de evaluación (1–10, opcionales individualmente)
    actitud_puntualidad  DECIMAL(3,1) CHECK (actitud_puntualidad  BETWEEN 1 AND 10),
    competencia_tecnica  DECIMAL(3,1) CHECK (competencia_tecnica  BETWEEN 1 AND 10),
    iniciativa_autonomia DECIMAL(3,1) CHECK (iniciativa_autonomia BETWEEN 1 AND 10),
    trabajo_equipo       DECIMAL(3,1) CHECK (trabajo_equipo       BETWEEN 1 AND 10),
    cumplimiento_tareas  DECIMAL(3,1) CHECK (cumplimiento_tareas  BETWEEN 1 AND 10),

    -- Nota global obligatoria (0–10) y comentario libre
    nota_global          DECIMAL(4,2) NOT NULL CHECK (nota_global BETWEEN 0 AND 10),
    comentario           TEXT,
    fecha_evaluacion     TIMESTAMP    NOT NULL DEFAULT NOW()
);
