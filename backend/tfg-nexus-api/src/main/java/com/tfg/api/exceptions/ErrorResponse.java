package com.tfg.api.exceptions;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Estructura para las respuestas de error de la API.
 */
public record ErrorResponse(
    int status,
    String message,
    LocalDateTime timestamp,
    Map<String, String> errors
) {
    /**
     * Constructor para errores sin detalles de validación.
     */
    public ErrorResponse(int status, String message) {
        this(status, message, LocalDateTime.now(), null);
    }
}
