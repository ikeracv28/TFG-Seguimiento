package com.tfg.api.models.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DTO para devolver la información detallada de un seguimiento.
 * Proporciona contexto sobre el estado de validación y el tutor responsable.
 */
public record SeguimientoResponse(
    Long id,
    Long practicaId,
    LocalDate fechaRegistro,
    Integer horasRealizadas,
    String descripcion,
    String estado,
    Long validadoPorId,
    String validadoPorNombre,
    String comentarioTutor,
    LocalDateTime fechaCreacion
) {}
