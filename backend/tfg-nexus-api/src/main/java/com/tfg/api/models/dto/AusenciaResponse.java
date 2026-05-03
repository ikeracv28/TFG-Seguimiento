package com.tfg.api.models.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record AusenciaResponse(
    Long id,
    Long practicaId,
    LocalDate fecha,
    String motivo,
    String tipo,
    boolean tieneJustificante,
    String nombreFichero,
    Long registradaPorId,
    String registradaPorNombre,
    Long revisadaPorId,
    String revisadaPorNombre,
    String comentarioRevision,
    LocalDateTime fechaCreacion
) {}
