package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
import com.tfg.api.services.PracticaService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Test de integración para PracticaController.
 * Verifica la seguridad por roles y las operaciones CRUD.
 */
@WebMvcTest(PracticaController.class)
@AutoConfigureMockMvc
class PracticaControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PracticaService practicaService;

    @MockBean
    private com.tfg.api.security.JwtUtils jwtUtils;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("ADMIN debe poder crear una práctica")
    @WithMockUser(roles = "ADMIN")
    void admin_should_create_practica() throws Exception {
        // Arrange
        PracticaRequest request = new PracticaRequest("P-2026-001", 1L, 2L, 3L, 4L, 
                                                     LocalDate.now(), LocalDate.now().plusMonths(3), 300, "BORRADOR");
        PracticaResponse response = new PracticaResponse(1L, "P-2026-001", 1L, "Alumno Test", 2L, "Tutor C", 3L, "Tutor E", 
                                                        4L, "Empresa S.A.", LocalDate.now(), LocalDate.now().plusMonths(3), 
                                                        300, "BORRADOR", LocalDateTime.now());

        when(practicaService.crear(any(PracticaRequest.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/api/v1/practicas")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.codigo").value("P-2026-001"))
                .andExpect(jsonPath("$.alumnoNombre").value("Alumno Test"));
    }

    @Test
    @DisplayName("ALUMNO no debe poder crear una práctica (403 Forbidden)")
    @WithMockUser(roles = "ALUMNO")
    void alumno_should_not_create_practica() throws Exception {
        // Arrange
        PracticaRequest request = new PracticaRequest("P-BAD", 1L, 2L, 3L, 4L, null, null, 100, "BORRADOR");

        // Act & Assert
        mockMvc.perform(post("/api/v1/practicas")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("TUTOR_CENTRO debe poder listar todas las prácticas")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_should_list_all_practicas() throws Exception {
        // Arrange
        PracticaResponse response = new PracticaResponse(1L, "P-001", 1L, "A", 2L, "B", 3L, "C", 4L, "D", null, null, 0, "ACTIVA", null);
        Page<PracticaResponse> page = new PageImpl<>(List.of(response));
        when(practicaService.listarTodas(any(Pageable.class))).thenReturn(page);

        // Act & Assert
        mockMvc.perform(get("/api/v1/practicas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].codigo").value("P-001"));
    }

    @Test
    @DisplayName("ADMIN debe poder cambiar el estado de una práctica")
    @WithMockUser(roles = "ADMIN")
    void admin_should_change_status() throws Exception {
        // Arrange
        PracticaResponse response = new PracticaResponse(1L, "P-001", 1L, "A", 2L, "B", 3L, "C", 4L, "D", null, null, 0, "ACTIVA", null);
        when(practicaService.cambiarEstado(eq(1L), eq("ACTIVA"))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(patch("/api/v1/practicas/1/estado")
                .with(csrf())
                .param("nuevoEstado", "ACTIVA"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("ACTIVA"));
    }
}
