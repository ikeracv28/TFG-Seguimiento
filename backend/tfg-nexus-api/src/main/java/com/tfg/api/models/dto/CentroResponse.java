package com.tfg.api.models.dto;

/**
 * DTO para la respuesta con los datos de un centro educativo.
 */
public record CentroResponse(
    Long id,
    String nombre,
    String direccion,
    String telefono,
    String email
) {}
