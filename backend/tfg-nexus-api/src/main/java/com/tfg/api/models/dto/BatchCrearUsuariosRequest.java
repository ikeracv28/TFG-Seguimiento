package com.tfg.api.models.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record BatchCrearUsuariosRequest(
    @NotEmpty(message = "La lista de usuarios no puede estar vacía")
    List<@Valid CreateUsuarioRequest> usuarios
) {}
