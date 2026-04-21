package com.tfg.api.exceptions;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Estructura estandarizada para todas las respuestas de error de la API.
 * 
 * @param status Código de estado HTTP (ej: 404, 400).
 * @param message Mensaje descriptivo para el desarrollador/usuario.
 * @param timestamp Marca de tiempo de cuándo ocurrió el error.
 * @param errors Mapa opcional para errores de validación de campos específicos (ej: email -> "formato inválido").
 */
public record ErrorResponse(
    int status,
    String message,
    LocalDateTime timestamp,
    Map<String, String> errors
) {
    /**
     * Constructor compacto para errores simples sin detalles de campos.
     */
    public ErrorResponse(int status, String message) {
        this(status, message, LocalDateTime.now(), null);
    }
}
