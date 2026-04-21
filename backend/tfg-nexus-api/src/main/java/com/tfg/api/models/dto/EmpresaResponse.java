package com.tfg.api.models.dto;

/**
 * Record para la transferencia de datos de Empresas colaboradoras.
 * 
 * @param id Identificador único.
 * @param nombre Nombre comercial o razón social.
 * @param cif Código de Identificación Fiscal.
 * @param direccion Ubicación de la sede.
 * @param emailContacto Email de contacto.
 * @param telefonoContacto Teléfono de contacto.
 */
public record EmpresaResponse(
    Long id,
    String nombre,
    String cif,
    String direccion,
    String emailContacto,
    String telefonoContacto
) {}
