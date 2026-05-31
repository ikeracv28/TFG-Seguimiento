package com.tfg.api.models.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record PlanificarTutoriasRequest(
        @NotNull LocalDate fecha,
        @NotNull LocalTime horaInicio,
        @NotNull @Positive Integer duracionMinutos,
        List<Long> ordenAlumnosIds
) {}
