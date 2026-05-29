package com.tfg.api.models.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record SeguimientoResponse(
    Long id,
    Long practicaId,
    LocalDate fechaRegistro,
    Double horasRealizadas,
    String descripcion,
    String estado,
    String tipo,
    Long validadoPorId,
    String validadoPorNombre,
    String comentarioTutor,
    LocalDateTime fechaCreacion,
    // Firma electrónica
    String firmaAlumnoImagen,
    String firmaAlumnoNombre,
    LocalDateTime firmaAlumnoFecha,
    String firmaTutorEmpresaImagen,
    String firmaTutorEmpresaNombre,
    LocalDateTime firmaTutorEmpresaFecha
) {}
