package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record AuditLogResponse(
    Long id,
    LocalDateTime fecha,
    String usuarioEmail,
    String modulo,
    String accion,
    Long entidadId,
    String descripcion
) {}
