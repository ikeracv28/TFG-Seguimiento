package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record NotificacionResponse(
        Long id,
        String tipo,
        String mensaje,
        boolean leida,
        LocalDateTime fechaCreacion
) {}
