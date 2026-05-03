-- V8: Módulo de ausencias del alumno durante el periodo de prácticas
-- Estados: PENDIENTE (registrada, sin revisar) -> JUSTIFICADA | INJUSTIFICADA

CREATE TABLE ausencias (
    id              BIGSERIAL PRIMARY KEY,
    practica_id     BIGINT        NOT NULL REFERENCES practicas(id),
    fecha           DATE          NOT NULL,
    motivo          TEXT          NOT NULL,
    tipo            VARCHAR(20)   NOT NULL DEFAULT 'PENDIENTE',
    -- Fichero justificante opcional (máx ~5 MB según límite application.properties)
    justificante    BYTEA,
    nombre_fichero  VARCHAR(255),
    mime_type       VARCHAR(100),
    registrada_por_id BIGINT      NOT NULL REFERENCES usuarios(id),
    revisada_por_id   BIGINT      REFERENCES usuarios(id),
    comentario_revision TEXT,
    fecha_creacion  TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ausencias_practica ON ausencias(practica_id);
CREATE INDEX idx_ausencias_tipo     ON ausencias(tipo);
