-- Tabla de auditoría centralizada agrupada por módulo
CREATE TABLE audit_logs (
    id          BIGSERIAL PRIMARY KEY,
    fecha       TIMESTAMP NOT NULL DEFAULT NOW(),
    usuario_email VARCHAR(100),
    modulo      VARCHAR(50)  NOT NULL,
    accion      VARCHAR(100) NOT NULL,
    entidad_id  BIGINT,
    descripcion TEXT
);

CREATE INDEX idx_audit_modulo  ON audit_logs (modulo);
CREATE INDEX idx_audit_fecha   ON audit_logs (fecha DESC);
CREATE INDEX idx_audit_usuario ON audit_logs (usuario_email);
