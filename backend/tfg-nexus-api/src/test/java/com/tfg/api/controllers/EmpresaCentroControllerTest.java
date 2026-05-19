package com.tfg.api.controllers;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.services.CentroService;
import com.tfg.api.services.EmpresaService;
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

// EmpresaController
@WebMvcTest(EmpresaController.class)
@AutoConfigureMockMvc
class EmpresaControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockBean private EmpresaService empresaService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    @Test
    @DisplayName("Usuario autenticado puede listar empresas")
    @WithMockUser
    void autenticado_lista_empresas() throws Exception {
        EmpresaResponse empresa = new EmpresaResponse(1L, "Nexus Corp", "B12345678",
                "Calle Mayor 1", "contacto@nexus.com", "600000000");
        when(empresaService.findAll()).thenReturn(List.of(empresa));

        mockMvc.perform(get("/api/v1/empresas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].nombre").value("Nexus Corp"))
                .andExpect(jsonPath("$[0].cif").value("B12345678"));
    }

    @Test
    @DisplayName("Sin autenticar no puede listar empresas — 401")
    void sin_autenticar_no_lista_empresas() throws Exception {
        mockMvc.perform(get("/api/v1/empresas"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Lista vacía cuando no hay empresas")
    @WithMockUser
    void lista_vacia_sin_empresas() throws Exception {
        when(empresaService.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/empresas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
