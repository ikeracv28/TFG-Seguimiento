package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.AusenciaRequest;
import com.tfg.api.models.dto.AusenciaResponse;
import com.tfg.api.services.AusenciaService;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AusenciaController.class)
@AutoConfigureMockMvc
class AusenciaControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private AusenciaService ausenciaService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private AusenciaResponse ausenciaResponse() {
        return new AusenciaResponse(1L, 10L, LocalDate.now().minusDays(1),
                "Motivo de prueba para test", "PENDIENTE",
                false, null, 1L, "Carlos García",
                null, null, null, LocalDateTime.now());
    }

    // ─── POST / ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede registrar una ausencia")
    @WithMockUser(username = "alumno@test.com", roles = "ALUMNO")
    void alumno_registra_ausencia() throws Exception {
        AusenciaRequest req = new AusenciaRequest(
                10L, LocalDate.now().minusDays(1), "Motivo de prueba para test");
        when(ausenciaService.registrar(any(AusenciaRequest.class), anyString()))
                .thenReturn(ausenciaResponse());

        mockMvc.perform(post("/api/v1/ausencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tipo").value("PENDIENTE"));
    }

    @Test
    @DisplayName("TUTOR_CENTRO no puede registrar ausencias — 403")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_no_puede_registrar_ausencia() throws Exception {
        AusenciaRequest req = new AusenciaRequest(
                10L, LocalDate.now().minusDays(1), "Motivo de prueba para test");

        mockMvc.perform(post("/api/v1/ausencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Sin autenticar no puede registrar ausencias — 401")
    void sin_autenticar_no_registra_ausencia() throws Exception {
        AusenciaRequest req = new AusenciaRequest(
                10L, LocalDate.now().minusDays(1), "Motivo de prueba para test");

        mockMvc.perform(post("/api/v1/ausencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Petición inválida devuelve 400 — motivo vacío")
    @WithMockUser(roles = "ALUMNO")
    void ausencia_motivo_vacio_devuelve_400() throws Exception {
        AusenciaRequest req = new AusenciaRequest(10L, LocalDate.now().minusDays(1), "");

        mockMvc.perform(post("/api/v1/ausencias")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ─── GET /practica/{id} ─────────────────────────────────────────────────

    @Test
    @DisplayName("ADMIN puede listar ausencias de una práctica")
    @WithMockUser(roles = "ADMIN")
    void admin_lista_ausencias_practica() throws Exception {
        when(ausenciaService.listarPorPractica(10L)).thenReturn(List.of(ausenciaResponse()));

        mockMvc.perform(get("/api/v1/ausencias/practica/10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].practicaId").value(10));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA puede listar ausencias de una práctica")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_lista_ausencias_practica() throws Exception {
        when(ausenciaService.listarPorPractica(10L)).thenReturn(List.of(ausenciaResponse()));

        mockMvc.perform(get("/api/v1/ausencias/practica/10"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Sin autenticar no puede listar ausencias — 401")
    void sin_autenticar_no_lista_ausencias() throws Exception {
        mockMvc.perform(get("/api/v1/ausencias/practica/10"))
                .andExpect(status().isUnauthorized());
    }

    // ─── GET /{id} ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede obtener detalle de una ausencia")
    @WithMockUser(roles = "ALUMNO")
    void alumno_obtiene_ausencia_por_id() throws Exception {
        when(ausenciaService.obtenerPorId(1L)).thenReturn(ausenciaResponse());

        mockMvc.perform(get("/api/v1/ausencias/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
    }

    // ─── PATCH /{id}/revisar ─────────────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_EMPRESA puede revisar una ausencia")
    @WithMockUser(username = "tutor@empresa.com", roles = "TUTOR_EMPRESA")
    void tutor_empresa_revisa_ausencia() throws Exception {
        AusenciaResponse revisada = new AusenciaResponse(1L, 10L, LocalDate.now().minusDays(1),
                "Motivo de prueba para test", "JUSTIFICADA",
                false, null, 1L, "Carlos García",
                2L, "Tutor Empresa", "Justificada correctamente", LocalDateTime.now());
        when(ausenciaService.revisar(anyLong(), anyString(), any(), anyString()))
                .thenReturn(revisada);

        mockMvc.perform(patch("/api/v1/ausencias/1/revisar")
                        .with(csrf())
                        .param("nuevoTipo", "JUSTIFICADA")
                        .param("comentario", "Justificada correctamente"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tipo").value("JUSTIFICADA"));
    }

    @Test
    @DisplayName("ALUMNO no puede revisar ausencias — 403")
    @WithMockUser(roles = "ALUMNO")
    void alumno_no_puede_revisar_ausencia() throws Exception {
        mockMvc.perform(patch("/api/v1/ausencias/1/revisar")
                        .with(csrf())
                        .param("nuevoTipo", "JUSTIFICADA"))
                .andExpect(status().isForbidden());
    }

    // ─── GET /{id}/justificante ─────────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_CENTRO puede descargar justificante")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_descarga_justificante() throws Exception {
        AusenciaService.JustificanteDto dto = new AusenciaService.JustificanteDto(
                new byte[]{1, 2, 3}, "image/jpeg", "justificante.jpg");
        when(ausenciaService.descargarJustificante(1L)).thenReturn(dto);

        mockMvc.perform(get("/api/v1/ausencias/1/justificante"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG));
    }

    @Test
    @DisplayName("Sin autenticar no puede descargar justificante — 401")
    void sin_autenticar_no_descarga_justificante() throws Exception {
        mockMvc.perform(get("/api/v1/ausencias/1/justificante"))
                .andExpect(status().isUnauthorized());
    }

    // ─── PATCH /{id}/justificante ────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede adjuntar justificante")
    @WithMockUser(username = "alumno@test.com", roles = "ALUMNO")
    void alumno_adjunta_justificante() throws Exception {
        when(ausenciaService.adjuntarJustificante(anyLong(), any(), anyString()))
                .thenReturn(ausenciaResponse());

        MockMultipartFile fichero = new MockMultipartFile(
                "fichero", "justificante.pdf", MediaType.APPLICATION_PDF_VALUE, new byte[]{1, 2, 3});

        mockMvc.perform(multipart("/api/v1/ausencias/1/justificante")
                        .file(fichero)
                        .with(request -> { request.setMethod("PATCH"); return request; })
                        .with(csrf()))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("TUTOR_EMPRESA no puede adjuntar justificante — 403")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_no_puede_adjuntar_justificante() throws Exception {
        MockMultipartFile fichero = new MockMultipartFile(
                "fichero", "j.pdf", MediaType.APPLICATION_PDF_VALUE, new byte[]{1});

        mockMvc.perform(multipart("/api/v1/ausencias/1/justificante")
                        .file(fichero)
                        .with(request -> { request.setMethod("PATCH"); return request; })
                        .with(csrf()))
                .andExpect(status().isForbidden());
    }

    // ─── DELETE /{id} ────────────────────────────────────────────────────────

    @Test
    @DisplayName("ALUMNO puede eliminar su ausencia")
    @WithMockUser(username = "alumno@test.com", roles = "ALUMNO")
    void alumno_elimina_ausencia() throws Exception {
        doNothing().when(ausenciaService).eliminar(1L, "alumno@test.com");

        mockMvc.perform(delete("/api/v1/ausencias/1").with(csrf()))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("TUTOR_CENTRO no puede eliminar ausencias — 403")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_no_puede_eliminar_ausencia() throws Exception {
        mockMvc.perform(delete("/api/v1/ausencias/1").with(csrf()))
                .andExpect(status().isForbidden());
    }
}
