package com.tfg.api.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tfg.api.models.dto.AuditLogResponse;
import com.tfg.api.models.dto.CreateUsuarioRequest;
import com.tfg.api.models.dto.UpdateUsuarioRequest;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.AdminService;
import com.tfg.api.services.AuditService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AdminController.class)
@AutoConfigureMockMvc
class AdminControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @MockBean private AdminService adminService;
    @MockBean private AuditService auditService;
    @MockBean private com.tfg.api.security.JwtUtils jwtUtils;
    @MockBean private com.tfg.api.security.TokenBlacklistService tokenBlacklistService;

    private UsuarioResponse usuarioResponse(Long id, String email, String rol) {
        return new UsuarioResponse(id, "TEST123A", "Test", "Usuario", email,
                Set.of(rol), null, true);
    }

    @Test
    @DisplayName("ADMIN puede listar usuarios")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_listar_usuarios() throws Exception {
        when(adminService.listarUsuarios()).thenReturn(
                List.of(usuarioResponse(1L, "alumno@test.com", "ROLE_ALUMNO")));

        mockMvc.perform(get("/api/v1/admin/usuarios"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].email").value("alumno@test.com"));
    }

    @Test
    @DisplayName("ALUMNO no puede listar usuarios — 403 Forbidden")
    @WithMockUser(roles = "ALUMNO")
    void alumno_no_puede_listar_usuarios() throws Exception {
        mockMvc.perform(get("/api/v1/admin/usuarios"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("ADMIN puede crear un usuario")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_crear_usuario() throws Exception {
        CreateUsuarioRequest req = new CreateUsuarioRequest(
                "DNI111111A", "Nuevo", "Usuario", "nuevo@test.com", "Password123", "ROLE_ALUMNO");
        when(adminService.crearUsuario(any(CreateUsuarioRequest.class)))
                .thenReturn(usuarioResponse(2L, "nuevo@test.com", "ROLE_ALUMNO"));

        mockMvc.perform(post("/api/v1/admin/usuarios")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value("nuevo@test.com"));
    }

    @Test
    @DisplayName("ADMIN puede editar un usuario")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_editar_usuario() throws Exception {
        UpdateUsuarioRequest req = new UpdateUsuarioRequest(
                "DNI222222B", "Editado", "Apellido", "editado@test.com", "ROLE_TUTOR_CENTRO");
        when(adminService.editarUsuario(eq(1L), any(UpdateUsuarioRequest.class)))
                .thenReturn(usuarioResponse(1L, "editado@test.com", "ROLE_TUTOR_CENTRO"));

        mockMvc.perform(put("/api/v1/admin/usuarios/1")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("editado@test.com"));
    }

    @Test
    @DisplayName("ADMIN puede hacer toggle de activo en un usuario")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_toggle_activo() throws Exception {
        when(adminService.toggleActivo(1L))
                .thenReturn(usuarioResponse(1L, "alumno@test.com", "ROLE_ALUMNO"));

        mockMvc.perform(patch("/api/v1/admin/usuarios/1/toggle-activo").with(csrf()))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("ADMIN puede listar audit logs sin filtro")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_listar_audit_logs() throws Exception {
        AuditLogResponse log = new AuditLogResponse(
                1L, LocalDateTime.now(), "admin@test.com", "USUARIOS", "CREAR", 1L, "Test");
        Page<AuditLogResponse> page = new PageImpl<>(List.of(log));
        when(auditService.listar(eq(null), any(Pageable.class))).thenReturn(page);

        mockMvc.perform(get("/api/v1/admin/audit-logs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].modulo").value("USUARIOS"));
    }

    @Test
    @DisplayName("ADMIN puede listar audit logs filtrados por modulo")
    @WithMockUser(roles = "ADMIN")
    void admin_puede_filtrar_audit_logs_por_modulo() throws Exception {
        AuditLogResponse log = new AuditLogResponse(
                2L, LocalDateTime.now(), "admin@test.com", "PRACTICAS", "EDITAR", 5L, "Editada");
        Page<AuditLogResponse> page = new PageImpl<>(List.of(log));
        when(auditService.listar(eq("PRACTICAS"), any(Pageable.class))).thenReturn(page);

        mockMvc.perform(get("/api/v1/admin/audit-logs").param("modulo", "PRACTICAS"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].modulo").value("PRACTICAS"));
    }

    @Test
    @DisplayName("TUTOR_CENTRO no puede acceder a audit logs — 403 Forbidden")
    @WithMockUser(roles = "TUTOR_CENTRO")
    void tutor_no_puede_acceder_audit_logs() throws Exception {
        mockMvc.perform(get("/api/v1/admin/audit-logs"))
                .andExpect(status().isForbidden());
    }
}
