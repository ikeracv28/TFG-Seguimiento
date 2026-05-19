-- V17: Soporte de adjuntos PDF en mensajes de chat
-- tipo: 'TEXTO' (por defecto) | 'ADJUNTO'
-- adjunto_datos: binario del fichero (bytea, max ~10 MB)
-- adjunto_nombre: nombre original del fichero
-- adjunto_tipo: MIME type (application/pdf, image/jpeg, image/png)

ALTER TABLE mensajes
    ADD COLUMN tipo           VARCHAR(20)  NOT NULL DEFAULT 'TEXTO',
    ADD COLUMN adjunto_nombre VARCHAR(255),
    ADD COLUMN adjunto_datos  BYTEA,
    ADD COLUMN adjunto_tipo   VARCHAR(100);
