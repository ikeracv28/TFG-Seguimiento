package com.tfg.api.controllers;

import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.UsuarioService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UsuarioController.class)
@AutoConfigureMockMvc
class UsuarioControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockBean private UsuarioService usuarioService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private UsuarioResponse usuarioAlumno() {
        return new UsuarioResponse(1L, "DNI12345A", "Carlos", "García", "alumno@test.com",
                Set.of("ROLE_ALUMNO"), "IES Test", true, false);
    }

    // ─── GET /me ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede obtener su perfil")
    @WithMockUser(username = "alumno@test.com", roles = "ALUMNO")
    void autenticado_obtiene_perfil() throws Exception {
        when(usuarioService.getMe()).thenReturn(usuarioAlumno());

        mockMvc.perform(get("/api/v1/usuarios/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("alumno@test.com"))
                .andExpect(jsonPath("$.nombre").value("Carlos"))
                .andExpect(jsonPath("$.tieneFoto").value(false));
    }

    @Test
    @DisplayName("Sin autenticar no puede obtener perfil — 401")
    void sin_autenticar_no_obtiene_perfil() throws Exception {
        mockMvc.perform(get("/api/v1/usuarios/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Tutor centro también puede obtener su perfil")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_obtiene_perfil() throws Exception {
        UsuarioResponse tutor = new UsuarioResponse(2L, "DNI99999B", "María", "López",
                "tutor@test.com", Set.of("ROLE_TUTOR_CENTRO"), "IES Test", true, true);
        when(usuarioService.getMe()).thenReturn(tutor);

        mockMvc.perform(get("/api/v1/usuarios/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tieneFoto").value(true));
    }

    // ─── POST /me/foto ──────────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede subir su foto")
    @WithMockUser
    void autenticado_sube_foto() throws Exception {
        doNothing().when(usuarioService).uploadFoto(any());

        MockMultipartFile foto = new MockMultipartFile(
                "file", "foto.jpg", MediaType.IMAGE_JPEG_VALUE, new byte[]{1, 2, 3});

        mockMvc.perform(multipart("/api/v1/usuarios/me/foto")
                        .file(foto)
                        .with(csrf()))
                .andExpect(status().isNoContent());

        verify(usuarioService).uploadFoto(any());
    }

    @Test
    @DisplayName("Sin autenticar no puede subir foto — 401")
    void sin_autenticar_no_sube_foto() throws Exception {
        MockMultipartFile foto = new MockMultipartFile(
                "file", "foto.jpg", MediaType.IMAGE_JPEG_VALUE, new byte[]{1, 2, 3});

        mockMvc.perform(multipart("/api/v1/usuarios/me/foto")
                        .file(foto)
                        .with(csrf()))
                .andExpect(status().isUnauthorized());
    }

    // ─── GET /{id}/foto ─────────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede obtener foto de otro usuario")
    @WithMockUser
    void autenticado_obtiene_foto() throws Exception {
        byte[] fotoBytes = new byte[]{1, 2, 3};
        when(usuarioService.getFoto(1L)).thenReturn(fotoBytes);
        when(usuarioService.getFotoContentType(1L)).thenReturn("image/jpeg");

        mockMvc.perform(get("/api/v1/usuarios/1/foto"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG));
    }

    @Test
    @DisplayName("Sin autenticar no puede obtener foto — 401")
    void sin_autenticar_no_obtiene_foto() throws Exception {
        mockMvc.perform(get("/api/v1/usuarios/1/foto"))
                .andExpect(status().isUnauthorized());
    }
}
