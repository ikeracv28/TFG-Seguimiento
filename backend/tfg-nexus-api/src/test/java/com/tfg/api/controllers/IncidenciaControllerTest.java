package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;
import com.tfg.api.services.IncidenciaService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(IncidenciaController.class)
@AutoConfigureMockMvc
class IncidenciaControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private IncidenciaService incidenciaService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private IncidenciaResponse incidenciaResponse() {
        return new IncidenciaResponse(1L, 10L, 1L, "Carlos García",
                "LABORAL", "Descripción de incidencia de prueba", "ABIERTA", LocalDateTime.now());
    }

    // ─── POST / ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede crear una incidencia")
    @WithMockUser(username = "alumno@test.com", roles = "ALUMNO")
    void alumno_crea_incidencia() throws Exception {
        IncidenciaRequest req = new IncidenciaRequest("LABORAL", "Descripción de incidencia de prueba");
        when(incidenciaService.crear(any(IncidenciaRequest.class), anyString()))
                .thenReturn(incidenciaResponse());

        mockMvc.perform(post("/api/v1/incidencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tipo").value("LABORAL"))
                .andExpect(jsonPath("$.estado").value("ABIERTA"));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA puede crear una incidencia")
    @WithMockUser(username = "tutor@empresa.com", roles = "TUTOR_EMPRESA")
    void tutor_empresa_crea_incidencia() throws Exception {
        IncidenciaRequest req = new IncidenciaRequest("TECNICA", "Descripción de incidencia de prueba");
        when(incidenciaService.crear(any(IncidenciaRequest.class), anyString()))
                .thenReturn(incidenciaResponse());

        mockMvc.perform(post("/api/v1/incidencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("ADMIN no puede crear incidencias — 403")
    @WithMockUser(roles = "ADMIN")
    void admin_no_puede_crear_incidencia() throws Exception {
        IncidenciaRequest req = new IncidenciaRequest("LABORAL", "Descripción de incidencia de prueba");

        mockMvc.perform(post("/api/v1/incidencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Sin autenticar no puede crear incidencias — 401")
    void sin_autenticar_no_crea_incidencia() throws Exception {
        IncidenciaRequest req = new IncidenciaRequest("LABORAL", "Descripción de incidencia de prueba");

        mockMvc.perform(post("/api/v1/incidencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Descripción demasiado corta devuelve 400")
    @WithMockUser(roles = "ALUMNO")
    void descripcion_corta_devuelve_400() throws Exception {
        IncidenciaRequest req = new IncidenciaRequest("LABORAL", "Corta");

        mockMvc.perform(post("/api/v1/incidencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET /practica/{id} ─────────────────────────────────────────────────

    @Test
    @DisplayName("ADMIN puede listar incidencias de una práctica")
    @WithMockUser(roles = "ADMIN")
    void admin_lista_incidencias_practica() throws Exception {
        when(incidenciaService.listarPorPractica(10L)).thenReturn(List.of(incidenciaResponse()));

        mockMvc.perform(get("/api/v1/incidencias/practica/10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].tipo").value("LABORAL"));
    }

    @Test
    @DisplayName("Sin autenticar no puede listar — 401")
    void sin_autenticar_no_lista() throws Exception {
        mockMvc.perform(get("/api/v1/incidencias/practica/10"))
                .andExpect(status().isUnauthorized());
    }

    // ─── GET /{id} ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede obtener incidencia por id")
    @WithMockUser
    void autenticado_obtiene_incidencia() throws Exception {
        when(incidenciaService.obtenerPorId(1L)).thenReturn(incidenciaResponse());

        mockMvc.perform(get("/api/v1/incidencias/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
    }

    // ─── PATCH /{id}/estado ──────────────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_CENTRO puede actualizar estado de una incidencia")
    @WithMockUser(username = "tutor@centro.com", roles = "TUTOR_CENTRO")
    void tutor_centro_actualiza_estado() throws Exception {
        IncidenciaResponse resuelta = new IncidenciaResponse(1L, 10L, 1L, "Carlos García",
                "LABORAL", "Descripción de incidencia de prueba", "RESUELTA", LocalDateTime.now());
        when(incidenciaService.actualizarEstado(eq(1L), eq("RESUELTA"), anyString()))
                .thenReturn(resuelta);

        mockMvc.perform(patch("/api/v1/incidencias/1/estado")
                        .with(csrf())
                        .param("nuevoEstado", "RESUELTA"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("RESUELTA"));
    }

    @Test
    @DisplayName("ALUMNO no puede actualizar estado — 403")
    @WithMockUser(roles = "ALUMNO")
    void alumno_no_puede_actualizar_estado() throws Exception {
        mockMvc.perform(patch("/api/v1/incidencias/1/estado")
                        .with(csrf())
                        .param("nuevoEstado", "RESUELTA"))
                .andExpect(status().isForbidden());
    }
}
