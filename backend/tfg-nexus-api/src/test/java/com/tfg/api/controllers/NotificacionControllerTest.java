package com.tfg.api.controllers;

import com.tfg.api.models.dto.NotificacionResponse;
import com.tfg.api.services.NotificacionService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(NotificacionController.class)
@AutoConfigureMockMvc
class NotificacionControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockBean private NotificacionService notificacionService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private NotificacionResponse notifResponse() {
        return new NotificacionResponse(1L, "CHAT", "Nuevo mensaje", false, LocalDateTime.now());
    }

    // ─── GET /me ────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede listar sus notificaciones")
    @WithMockUser
    void autenticado_lista_notificaciones() throws Exception {
        when(notificacionService.listarParaUsuario()).thenReturn(List.of(notifResponse()));

        mockMvc.perform(get("/api/v1/notificaciones/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].tipo").value("CHAT"))
                .andExpect(jsonPath("$[0].leida").value(false));
    }

    @Test
    @DisplayName("Sin autenticar no puede listar notificaciones — 401")
    void sin_autenticar_no_lista_notificaciones() throws Exception {
        mockMvc.perform(get("/api/v1/notificaciones/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Lista vacía cuando no hay notificaciones")
    @WithMockUser
    void lista_vacia_cuando_no_hay_notificaciones() throws Exception {
        when(notificacionService.listarParaUsuario()).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/notificaciones/me"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    // ─── GET /me/no-leidas ──────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede contar no leídas")
    @WithMockUser
    void autenticado_cuenta_no_leidas() throws Exception {
        when(notificacionService.contarNoLeidas()).thenReturn(3L);

        mockMvc.perform(get("/api/v1/notificaciones/me/no-leidas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(3));
    }

    @Test
    @DisplayName("Sin autenticar no puede contar no leídas — 401")
    void sin_autenticar_no_cuenta_no_leidas() throws Exception {
        mockMvc.perform(get("/api/v1/notificaciones/me/no-leidas"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Devuelve cero cuando todas están leídas")
    @WithMockUser
    void cero_no_leidas() throws Exception {
        when(notificacionService.contarNoLeidas()).thenReturn(0L);

        mockMvc.perform(get("/api/v1/notificaciones/me/no-leidas"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(0));
    }

    // ─── PATCH /{id}/leer ───────────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede marcar una notificación como leída")
    @WithMockUser
    void autenticado_marca_leida() throws Exception {
        doNothing().when(notificacionService).marcarLeida(1L);

        mockMvc.perform(patch("/api/v1/notificaciones/1/leer").with(csrf()))
                .andExpect(status().isNoContent());

        verify(notificacionService).marcarLeida(1L);
    }

    @Test
    @DisplayName("Sin autenticar no puede marcar como leída — 401")
    void sin_autenticar_no_marca_leida() throws Exception {
        mockMvc.perform(patch("/api/v1/notificaciones/1/leer").with(csrf()))
                .andExpect(status().isUnauthorized());
    }

    // ─── PATCH /me/leer-todas ───────────────────────────────────────────────

    @Test
    @DisplayName("Usuario autenticado puede marcar todas como leídas")
    @WithMockUser
    void autenticado_marca_todas_leidas() throws Exception {
        doNothing().when(notificacionService).marcarTodasLeidas();

        mockMvc.perform(patch("/api/v1/notificaciones/me/leer-todas").with(csrf()))
                .andExpect(status().isNoContent());

        verify(notificacionService).marcarTodasLeidas();
    }

    @Test
    @DisplayName("Sin autenticar no puede marcar todas como leídas — 401")
    void sin_autenticar_no_marca_todas_leidas() throws Exception {
        mockMvc.perform(patch("/api/v1/notificaciones/me/leer-todas").with(csrf()))
                .andExpect(status().isUnauthorized());
    }
}
