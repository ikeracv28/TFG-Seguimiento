package com.tfg.api.services;

import com.tfg.api.models.dto.AuthResponse;
import com.tfg.api.models.dto.LoginRequest;
import com.tfg.api.models.dto.RegisterRequest;
import com.tfg.api.models.dto.UsuarioResponse;

/**
 * Interfaz de servicio para la gestión de autenticación en Nexus-TFG.
 */
public interface AuthService {

    /**
     * Registra un nuevo usuario y devuelve sus credenciales de acceso (JWT).
     */
    AuthResponse registrar(RegisterRequest request);

    /**
     * Realiza el login oficial del sistema y genera el Token JWT.
     */
    AuthResponse login(LoginRequest request);

    /**
     * Invalida el token JWT activo añadiendo su JTI a la blacklist.
     */
    void logout(String token);

    /**
     * Devuelve el perfil completo del usuario autenticado actualmente.
     */
    UsuarioResponse me();
}
