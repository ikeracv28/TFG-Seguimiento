package com.tfg.api.controllers;

import com.tfg.api.models.dto.MensajeResponse;
import com.tfg.api.services.MensajeService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(MensajeController.class)
@AutoConfigureMockMvc
class MensajeControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockBean private MensajeService mensajeService;
    @MockBean private SimpMessagingTemplate messagingTemplate;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private MensajeResponse mensajeMock() {
        return new MensajeResponse(1L, 1L, 2L, "Alumno", "Ejemplo",
                "Hola desde el historial", LocalDateTime.now(), "ALUMNO", "TEXTO", null);
    }

    @Test
    @DisplayName("ALUMNO puede obtener el historial del canal ALUMNO")
    @WithMockUser(roles = "ALUMNO")
    void alumno_puede_ver_historial() throws Exception {
        when(mensajeService.listarPorPractica(1L, "ALUMNO")).thenReturn(List.of(mensajeMock()));

        mockMvc.perform(get("/api/v1/mensajes/practica/1").param("canal", "ALUMNO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].contenido").value("Hola desde el historial"))
                .andExpect(jsonPath("$[0].remitenteNombre").value("Alumno"))
                .andExpect(jsonPath("$[0].canal").value("ALUMNO"));
    }

    @Test
    @DisplayName("TUTOR_CENTRO puede obtener el historial del canal ALUMNO")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_centro_puede_ver_historial() throws Exception {
        when(mensajeService.listarPorPractica(1L, "ALUMNO")).thenReturn(List.of(mensajeMock()));

        mockMvc.perform(get("/api/v1/mensajes/practica/1").param("canal", "ALUMNO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    @DisplayName("TUTOR_EMPRESA puede obtener el historial del canal TUTORES")
    @WithMockUser(roles = "TUTOR_EMPRESA")
    void tutor_empresa_puede_ver_historial() throws Exception {
        MensajeResponse mockTutores = new MensajeResponse(2L, 1L, 3L, "Tutor", "Empresa",
                "Mensaje canal tutores", LocalDateTime.now(), "TUTORES", "TEXTO", null);
        when(mensajeService.listarPorPractica(1L, "TUTORES")).thenReturn(List.of(mockTutores));

        mockMvc.perform(get("/api/v1/mensajes/practica/1").param("canal", "TUTORES"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].canal").value("TUTORES"));
    }

    @Test
    @DisplayName("ADMIN puede obtener el historial de mensajes")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_ver_historial() throws Exception {
        when(mensajeService.listarPorPractica(1L, "ALUMNO")).thenReturn(List.of(mensajeMock()));

        mockMvc.perform(get("/api/v1/mensajes/practica/1").param("canal", "ALUMNO"))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Sin parámetro canal usa ALUMNO por defecto")
    @WithMockUser(roles = "ALUMNO")
    void historial_usa_canal_alumno_por_defecto() throws Exception {
        when(mensajeService.listarPorPractica(1L, "ALUMNO")).thenReturn(List.of(mensajeMock()));

        mockMvc.perform(get("/api/v1/mensajes/practica/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].canal").value("ALUMNO"));
    }

    @Test
    @DisplayName("Historial sin mensajes devuelve array JSON vacío")
    @WithMockUser(roles = "ALUMNO")
    void historial_vacio_devuelve_array_vacio() throws Exception {
        when(mensajeService.listarPorPractica(99L, "ALUMNO")).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/mensajes/practica/99").param("canal", "ALUMNO"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
