package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record MensajeResponse(
    Long id,
    Long practicaId,
    Long remitenteId,
    String remitenteNombre,
    String remitenteApellidos,
    String contenido,
    LocalDateTime fechaEnvio
) {}
