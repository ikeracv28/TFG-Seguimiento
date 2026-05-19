package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.EvaluacionFinalRequest;
import com.tfg.api.models.dto.EvaluacionFinalResponse;
import com.tfg.api.services.EvaluacionFinalService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(EvaluacionFinalController.class)
@AutoConfigureMockMvc
class EvaluacionFinalControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private EvaluacionFinalService evaluacionService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private EvaluacionFinalRequest requestValido() {
        return new EvaluacionFinalRequest(
                BigDecimal.valueOf(8.0), BigDecimal.valueOf(7.5),
                BigDecimal.valueOf(9.0), BigDecimal.valueOf(8.0),
                BigDecimal.valueOf(7.0), BigDecimal.valueOf(7.9),
                "Buen rendimiento general");
    }

    private EvaluacionFinalResponse evaluacionResponse() {
        return new EvaluacionFinalResponse(
                1L, 10L, "Carlos García",
                BigDecimal.valueOf(8.0), BigDecimal.valueOf(7.5),
                BigDecimal.valueOf(9.0), BigDecimal.valueOf(8.0),
                BigDecimal.valueOf(7.0), BigDecimal.valueOf(7.9),
                "Buen rendimiento general",
                5L, "Tutor Empresa", LocalDateTime.now());
    }

    // ─── POST /practica/{id} ─────────────────────────────────────────────────

    @Test
    @DisplayName("TUTOR_EMPRESA puede crear evaluación de una práctica")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_crea_evaluacion() throws Exception {
        when(evaluacionService.evaluar(eq(10L), any(EvaluacionFinalRequest.class)))
                .thenReturn(evaluacionResponse());

        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestValido())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.notaGlobal").value(7.9))
                .andExpect(jsonPath("$.alumnoNombre").value("Carlos García"));
    }

    @Test
    @DisplayName("TUTOR_CENTRO no puede crear evaluación — 403")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_no_puede_evaluar() throws Exception {
        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestValido())))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("ALUMNO no puede crear evaluación — 403")
    @WithMockUser(roles = "ALUMNO")
    void alumno_no_puede_evaluar() throws Exception {
        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestValido())))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Sin autenticar no puede crear evaluación — 401")
    void sin_autenticar_no_puede_evaluar() throws Exception {
        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestValido())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Nota global null devuelve 400")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void nota_global_null_devuelve_400() throws Exception {
        EvaluacionFinalRequest invalido = new EvaluacionFinalRequest(
                null, null, null, null, null, null, null);

        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalido)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Nota global fuera de rango (>10) devuelve 400")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void nota_global_fuera_de_rango_devuelve_400() throws Exception {
        EvaluacionFinalRequest invalido = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(11.0), null);

        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalido)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("TUTOR_EMPRESA puede evaluar solo con nota global (criterios opcionales)")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void evaluacion_solo_nota_global_es_valida() throws Exception {
        EvaluacionFinalRequest soloGlobal = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(8.5), null);
        when(evaluacionService.evaluar(eq(10L), any(EvaluacionFinalRequest.class)))
                .thenReturn(evaluacionResponse());

        mockMvc.perform(post("/api/v1/evaluaciones/practica/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(soloGlobal)))
                .andExpect(status().isOk());
    }

    // ─── GET /practica/{id} ──────────────────────────────────────────────────

    @Test
    @DisplayName("ADMIN puede obtener evaluación de una práctica")
    @WithMockUser(roles = "ADMIN")
    void admin_obtiene_evaluacion() throws Exception {
        when(evaluacionService.obtenerPorPractica(10L))
                .thenReturn(Optional.of(evaluacionResponse()));

        mockMvc.perform(get("/api/v1/evaluaciones/practica/10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.practicaId").value(10))
                .andExpect(jsonPath("$.tutorEmpresaNombre").value("Tutor Empresa"));
    }

    @Test
    @DisplayName("ALUMNO puede ver su propia evaluación")
    @WithMockUser(roles = "ALUMNO")
    void alumno_puede_ver_evaluacion() throws Exception {
        when(evaluacionService.obtenerPorPractica(10L))
                .thenReturn(Optional.of(evaluacionResponse()));

        mockMvc.perform(get("/api/v1/evaluaciones/practica/10"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Devuelve 204 cuando no existe evaluación para la práctica")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void devuelve_204_cuando_no_existe_evaluacion() throws Exception {
        when(evaluacionService.obtenerPorPractica(99L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/v1/evaluaciones/practica/99"))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("TUTOR_CENTRO puede ver evaluación")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_puede_ver_evaluacion() throws Exception {
        when(evaluacionService.obtenerPorPractica(10L))
                .thenReturn(Optional.of(evaluacionResponse()));

        mockMvc.perform(get("/api/v1/evaluaciones/practica/10"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Sin autenticar no puede ver evaluación — 401")
    void sin_autenticar_no_puede_ver_evaluacion() throws Exception {
        mockMvc.perform(get("/api/v1/evaluaciones/practica/10"))
                .andExpect(status().isUnauthorized());
    }
}
