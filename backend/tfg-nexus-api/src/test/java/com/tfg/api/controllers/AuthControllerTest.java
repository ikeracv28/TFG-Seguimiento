package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.AuthResponse;
import com.tfg.api.models.dto.LoginRequest;
import com.tfg.api.models.dto.RegisterRequest;
import com.tfg.api.services.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Test de integración para el controlador de autenticación.
 * Verifica la capa Web, validaciones y manejo de excepciones.
 */
@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false) // Deshabilitamos filtros de seguridad reales para probar solo el controlador
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AuthService authService;

    @MockBean
    private com.tfg.api.security.JwtUtils jwtUtils;

    @MockBean
    private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("Debe registrar un usuario y devolver 201 Created")
    void should_register_user_successfully() throws Exception {
        // Arrange
        RegisterRequest request = new RegisterRequest("12345678A", "Iker", "Acevedo", "iker@test.com", "Test@12345!");
        AuthResponse response = new AuthResponse(1L, "mock-jwt-token", "iker@test.com", "Iker Acevedo", Set.of("ROLE_ALUMNO"));

        when(authService.registrar(any(RegisterRequest.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("mock-jwt-token"))
                .andExpect(jsonPath("$.email").value("iker@test.com"));
    }

    @Test
    @DisplayName("Debe devolver 400 Bad Request cuando el email es inválido")
    void should_return_400_when_email_invalid() throws Exception {
        // Arrange (Email sin formato correcto)
        RegisterRequest request = new RegisterRequest("12345678A", "Iker", "Acevedo", "email-incorrecto", "password123");

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.errors.email").exists());
    }

    @Test
    @DisplayName("[A07] Logout devuelve 204 No Content con token Bearer válido")
    @WithMockUser
    void should_logout_and_return_204() throws Exception {
        doNothing().when(authService).logout(anyString());

        mockMvc.perform(post("/api/v1/auth/logout")
                .header("Authorization", "Bearer test-token-valido"))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("Debe devolver 401 Unauthorized ante credenciales inválidas")
    void should_return_401_on_bad_credentials() throws Exception {
        // Arrange
        LoginRequest request = new LoginRequest("test@test.com", "wrong-pass");
        when(authService.login(any(LoginRequest.class))).thenThrow(new BadCredentialsException("Credenciales inválidas"));

        // Act & Assert
        mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Credenciales de acceso inválidas"));
    }
}
