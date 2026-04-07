package com.tfg.api.controllers;

import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controlador para la administración de usuarios y gestión de perfiles.
 */
@RestController
@RequestMapping("/api/v1/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    // Recuperación del perfil del usuario autenticado para la sincronización del estado en el cliente
    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> getMe() {
        return ResponseEntity.ok(usuarioService.getMe());
    }
}
