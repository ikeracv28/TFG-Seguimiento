package com.tfg.api.models.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DTO para devolver la información detallada de una Práctica.
 * Aplana las relaciones para facilitar el consumo desde el Frontend Flutter.
 */
public record PracticaResponse(
    Long id,
    String codigo,
    Long alumnoId,
    String alumnoNombre,
    Long tutorCentroId,
    String tutorCentroNombre,
    Long tutorEmpresaId,
    String tutorEmpresaNombre,
    Long empresaId,
    String empresaNombre,
    LocalDate fechaInicio,
    LocalDate fechaFin,
    Integer horasTotales,
    String estado,
    LocalDateTime fechaCreacion
) {}
