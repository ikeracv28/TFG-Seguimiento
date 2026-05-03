CREATE TABLE IF NOT EXISTS mensajes (
    id           BIGSERIAL PRIMARY KEY,
    practica_id  BIGINT    NOT NULL REFERENCES practicas(id) ON DELETE CASCADE,
    remitente_id BIGINT    NOT NULL REFERENCES usuarios(id),
    contenido    TEXT      NOT NULL,
    fecha_envio  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mensajes_practica ON mensajes (practica_id, fecha_envio DESC);
