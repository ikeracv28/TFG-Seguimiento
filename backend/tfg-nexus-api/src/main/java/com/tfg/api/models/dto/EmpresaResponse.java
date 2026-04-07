package com.tfg.api.models.dto;

/**
 * DTO para la respuesta con los datos de una empresa.
 */
public record EmpresaResponse(
    Long id,
    String nombre,
    String cif,
    String direccion,
    String emailContacto,
    String telefonoContacto
) {}
