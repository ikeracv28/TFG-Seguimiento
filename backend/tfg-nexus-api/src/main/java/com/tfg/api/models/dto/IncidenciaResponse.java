package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record IncidenciaResponse(
    Long id,
    Long practicaId,
    Long creadaPorId,
    String creadaPorNombre,
    String tipo,
    String descripcion,
    String estado,
    LocalDateTime fechaCreacion,
    String resueltaPorNombre,
    LocalDateTime fechaResolucion
) {}
