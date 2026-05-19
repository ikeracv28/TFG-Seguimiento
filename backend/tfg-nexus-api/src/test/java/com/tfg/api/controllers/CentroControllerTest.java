package com.tfg.api.controllers;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.services.CentroService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(CentroController.class)
@AutoConfigureMockMvc
class CentroControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockBean private CentroService centroService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    @Test
    @DisplayName("Usuario autenticado puede listar centros")
    @WithMockUser
    void autenticado_lista_centros() throws Exception {
        CentroResponse centro = new CentroResponse(1L, "IES Nexus", "Calle Mayor 1",
                "600000000", "info@ies-nexus.edu");
        when(centroService.findAll()).thenReturn(List.of(centro));

        mockMvc.perform(get("/api/v1/centros"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nombre").value("IES Nexus"))
                .andExpect(jsonPath("$[0].email").value("info@ies-nexus.edu"));
    }

    @Test
    @DisplayName("Sin autenticar no puede listar centros — 401")
    void sin_autenticar_no_lista_centros() throws Exception {
        mockMvc.perform(get("/api/v1/centros"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Lista vacía cuando no hay centros")
    @WithMockUser
    void lista_vacia_sin_centros() throws Exception {
        when(centroService.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/centros"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
