package com.tfg.api.models.dto;

/**
 * Record para la transferencia de datos de Centros educativos.
 * 
 * @param id Identificador único.
 * @param nombre Nombre del instituto.
 * @param direccion Ubicación física.
 * @param telefono Teléfono de contacto.
 * @param email Correo institucional.
 */
public record CentroResponse(
    Long id,
    String nombre,
    String direccion,
    String telefono,
    String email
) {}
