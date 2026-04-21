package com.tfg.api.controllers;

import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controlador para la gestión de usuarios y perfiles.
 */
@RestController
@RequestMapping("/api/v1/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    /**
     * Devuelve el perfil del usuario autenticado actualmente.
     * Útil para que el cliente Flutter sincronice el estado tras el Login.
     */
    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> getMe() {
        return ResponseEntity.ok(usuarioService.getMe());
    }
}
