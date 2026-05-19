package com.tfg.api.models.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO para crear o actualizar una empresa colaboradora.
 */
public record EmpresaRequest(

    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 100)
    String nombre,

    @NotBlank(message = "El CIF es obligatorio")
    @Size(max = 20)
    String cif,

    String direccion,

    @Email(message = "El email no tiene formato válido")
    @Size(max = 100)
    String emailContacto,

    @Size(max = 20)
    String telefonoContacto
) {}
