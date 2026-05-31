package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record TutoriaResponse(
        Long id,
        Long alumnoId,
        String alumnoNombre,
        String alumnoEmail,
        LocalDateTime fechaHora,
        Integer duracionMinutos,
        Boolean notificado
) {}
