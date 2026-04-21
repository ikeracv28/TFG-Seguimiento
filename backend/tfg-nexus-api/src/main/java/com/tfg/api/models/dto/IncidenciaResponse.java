package com.tfg.api.models.dto;

import java.time.LocalDateTime;

/**
 * DTO de solo lectura para exponer incidencias.
 * No incluye información sensible de resolución interna.
 */
public record IncidenciaResponse(
    Long id,
    Long practicaId,
    Long creadaPorId,
    String creadaPorNombre,
    String tipo,
    String descripcion,
    String estado,
    LocalDateTime fechaCreacion
) {}
