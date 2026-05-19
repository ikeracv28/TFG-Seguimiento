package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.services.SeguimientoService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(SeguimientoController.class)
@AutoConfigureMockMvc
class SeguimientoControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private SeguimientoService seguimientoService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private SeguimientoResponse seguimientoResponse(String estado) {
        return new SeguimientoResponse(1L, 10L, LocalDate.now(), 4.0,
                "Descripción de tareas realizadas hoy", estado,
                "DIARIO", null, null, null, LocalDateTime.now());
    }

    // ─── POST / ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede registrar un seguimiento")
    @WithMockUser(roles = "ALUMNO")
    void alumno_registra_seguimiento() throws Exception {
        SeguimientoRequest req = new SeguimientoRequest(
                10L, LocalDate.now(), 4.0, "Descripción de tareas realizadas hoy", null);
        when(seguimientoService.registrar(any(SeguimientoRequest.class)))
                .thenReturn(seguimientoResponse("PENDIENTE_EMPRESA"));

        mockMvc.perform(post("/api/v1/seguimientos")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.estado").value("PENDIENTE_EMPRESA"))
                .andExpect(jsonPath("$.horasRealizadas").value(4));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA no puede registrar seguimiento — 403")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_no_puede_registrar() throws Exception {
        SeguimientoRequest req = new SeguimientoRequest(
                10L, LocalDate.now(), 4.0, "Descripción de tareas realizadas hoy", null);

        mockMvc.perform(post("/api/v1/seguimientos")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Sin autenticar no puede registrar — 401")
    void sin_autenticar_no_registra() throws Exception {
        SeguimientoRequest req = new SeguimientoRequest(
                10L, LocalDate.now(), 4.0, "Descripción de tareas realizadas hoy", null);

        mockMvc.perform(post("/api/v1/seguimientos")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Horas <= 0 devuelve 400")
    @WithMockUser(roles = "ALUMNO")
    void horas_invalidas_devuelve_400() throws Exception {
        SeguimientoRequest req = new SeguimientoRequest(
                10L, LocalDate.now(), 0.0, "Descripción de tareas realizadas hoy", null);

        mockMvc.perform(post("/api/v1/seguimientos")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET /practica/{id} ─────────────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_CENTRO puede listar seguimientos de una práctica")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_lista_seguimientos() throws Exception {
        when(seguimientoService.listarPorPractica(10L))
                .thenReturn(List.of(seguimientoResponse("COMPLETADO")));

        mockMvc.perform(get("/api/v1/seguimientos/practica/10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].estado").value("COMPLETADO"));
    }

    @Test
    @DisplayName("Sin autenticar no puede listar — 401")
    void sin_autenticar_no_lista() throws Exception {
        mockMvc.perform(get("/api/v1/seguimientos/practica/10"))
                .andExpect(status().isUnauthorized());
    }

    // ─── PATCH /{id}/validar-empresa ─────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_EMPRESA puede aprobar un seguimiento")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_valida_seguimiento() throws Exception {
        when(seguimientoService.validarEmpresa(eq(1L), eq("PENDIENTE_CENTRO"), isNull()))
                .thenReturn(seguimientoResponse("PENDIENTE_CENTRO"));

        mockMvc.perform(patch("/api/v1/seguimientos/1/validar-empresa")
                        .with(csrf())
                        .param("nuevoEstado", "PENDIENTE_CENTRO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("PENDIENTE_CENTRO"));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA puede rechazar con motivo")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_rechaza_seguimiento() throws Exception {
        when(seguimientoService.validarEmpresa(eq(1L), eq("RECHAZADO"), eq("Horas incorrectas")))
                .thenReturn(seguimientoResponse("RECHAZADO"));

        mockMvc.perform(patch("/api/v1/seguimientos/1/validar-empresa")
                        .with(csrf())
                        .param("nuevoEstado", "RECHAZADO")
                        .param("motivo", "Horas incorrectas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("RECHAZADO"));
    }

    @Test
    @DisplayName("ALUMNO no puede validar — 403")
    @WithMockUser(roles = "ALUMNO")
    void alumno_no_puede_validar_empresa() throws Exception {
        mockMvc.perform(patch("/api/v1/seguimientos/1/validar-empresa")
                        .with(csrf())
                        .param("nuevoEstado", "PENDIENTE_CENTRO"))
                .andExpect(status().isForbidden());
    }

    // ─── PATCH /{id}/validar-centro ──────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_CENTRO puede completar un seguimiento")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_valida_seguimiento() throws Exception {
        when(seguimientoService.validarCentro(1L))
                .thenReturn(seguimientoResponse("COMPLETADO"));

        mockMvc.perform(patch("/api/v1/seguimientos/1/validar-centro").with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("COMPLETADO"));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA no puede validar como centro — 403")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_no_puede_validar_centro() throws Exception {
        mockMvc.perform(patch("/api/v1/seguimientos/1/validar-centro").with(csrf()))
                .andExpect(status().isForbidden());
    }

    // ─── DELETE /{id} ────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede eliminar su seguimiento")
    @WithMockUser(roles = "ALUMNO")
    void alumno_elimina_seguimiento() throws Exception {
        doNothing().when(seguimientoService).eliminar(1L);

        mockMvc.perform(delete("/api/v1/seguimientos/1").with(csrf()))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("TUTOR_CENTRO no puede eliminar — 403")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_no_puede_eliminar() throws Exception {
        mockMvc.perform(delete("/api/v1/seguimientos/1").with(csrf()))
                .andExpect(status().isForbidden());
    }
}
