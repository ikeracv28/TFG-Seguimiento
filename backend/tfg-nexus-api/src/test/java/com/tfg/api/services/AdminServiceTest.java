package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.CreateUsuarioRequest;
import com.tfg.api.models.dto.UpdateUsuarioRequest;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.models.entity.Rol;
import com.tfg.api.models.repository.RolRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class AdminServiceTest {

    @Autowired private AdminService adminService;
    @Autowired private RolRepository rolRepository;
    @Autowired private UsuarioRepository usuarioRepository;

    @BeforeEach
    void setUp() {
        for (String rol : List.of("ROLE_ALUMNO", "ROLE_TUTOR_CENTRO", "ROLE_TUTOR_EMPRESA", "ROLE_ADMIN")) {
            if (rolRepository.findByNombre(rol).isEmpty()) {
                rolRepository.save(Rol.builder().nombre(rol).build());
            }
        }
    }

    private CreateUsuarioRequest crearRequest(String dni, String email, String rol) {
        return new CreateUsuarioRequest(dni, "Test", "Admin", email, "Password123", rol);
    }

    @Test
    @DisplayName("Admin puede crear un usuario alumno")
    void admin_puede_crear_usuario_alumno() {
        UsuarioResponse resp = adminService.crearUsuario(
                crearRequest("AD000001A", "nuevo.alumno@test.com", "ROLE_ALUMNO"));

        assertThat(resp.id()).isNotNull();
        assertThat(resp.email()).isEqualTo("nuevo.alumno@test.com");
        assertThat(resp.roles()).contains("ROLE_ALUMNO");
    }

    @Test
    @DisplayName("Admin puede crear un usuario tutor de centro")
    void admin_puede_crear_tutor_centro() {
        UsuarioResponse resp = adminService.crearUsuario(
                crearRequest("AD000002B", "tutor.centro@test.com", "ROLE_TUTOR_CENTRO"));

        assertThat(resp.roles()).contains("ROLE_TUTOR_CENTRO");
    }

    @Test
    @DisplayName("No se permite crear usuario con rol invalido")
    void no_permite_rol_invalido() {
        assertThatThrownBy(() ->
            adminService.crearUsuario(crearRequest("AD000003C", "x@test.com", "ROLE_SUPERADMIN"))
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("Rol no válido");
    }

    @Test
    @DisplayName("No se permite crear usuario con email ya registrado")
    void no_permite_email_duplicado() {
        adminService.crearUsuario(crearRequest("AD000004D", "dup@test.com", "ROLE_ALUMNO"));

        assertThatThrownBy(() ->
            adminService.crearUsuario(crearRequest("AD000005E", "dup@test.com", "ROLE_ALUMNO"))
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("email");
    }

    @Test
    @DisplayName("No se permite crear usuario con DNI ya registrado")
    void no_permite_dni_duplicado() {
        adminService.crearUsuario(crearRequest("AD000006F", "primero@test.com", "ROLE_ALUMNO"));

        assertThatThrownBy(() ->
            adminService.crearUsuario(crearRequest("AD000006F", "segundo@test.com", "ROLE_ALUMNO"))
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("email o DNI");
    }

    @Test
    @DisplayName("Admin puede listar todos los usuarios")
    void admin_puede_listar_usuarios() {
        adminService.crearUsuario(crearRequest("AD000007G", "lista1@test.com", "ROLE_ALUMNO"));
        adminService.crearUsuario(crearRequest("AD000008H", "lista2@test.com", "ROLE_TUTOR_CENTRO"));

        List<UsuarioResponse> lista = adminService.listarUsuarios();

        assertThat(lista).hasSizeGreaterThanOrEqualTo(2);
    }

    @Test
    @DisplayName("Admin puede activar y desactivar un usuario con toggleActivo")
    void toggle_activo_cambia_estado() {
        UsuarioResponse creado = adminService.crearUsuario(
                crearRequest("AD000009I", "toggle@test.com", "ROLE_ALUMNO"));

        UsuarioResponse desactivado = adminService.toggleActivo(creado.id());
        assertThat(desactivado.activo()).isFalse();

        UsuarioResponse reactivado = adminService.toggleActivo(creado.id());
        assertThat(reactivado.activo()).isTrue();
    }

    @Test
    @DisplayName("toggleActivo lanza excepcion si el usuario no existe")
    void toggle_activo_usuario_no_encontrado() {
        assertThatThrownBy(() -> adminService.toggleActivo(99999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("Admin puede editar datos de un usuario sin cambiar la contrasena")
    void admin_puede_editar_usuario() {
        UsuarioResponse creado = adminService.crearUsuario(
                crearRequest("AD000010J", "antes@test.com", "ROLE_ALUMNO"));

        UpdateUsuarioRequest editReq = new UpdateUsuarioRequest(
                "AD000010J", "Nuevo", "Apellido", "despues@test.com", "ROLE_TUTOR_CENTRO");
        UsuarioResponse editado = adminService.editarUsuario(creado.id(), editReq);

        assertThat(editado.email()).isEqualTo("despues@test.com");
        assertThat(editado.nombre()).isEqualTo("Nuevo");
        assertThat(editado.roles()).contains("ROLE_TUTOR_CENTRO");
    }

    @Test
    @DisplayName("Editar usuario con email de otro usuario lanza excepcion")
    void editar_usuario_email_duplicado_lanza_excepcion() {
        adminService.crearUsuario(crearRequest("AD000011K", "ocupado@test.com", "ROLE_ALUMNO"));
        UsuarioResponse segundo = adminService.crearUsuario(
                crearRequest("AD000012L", "libre@test.com", "ROLE_ALUMNO"));

        UpdateUsuarioRequest editReq = new UpdateUsuarioRequest(
                "AD000012L", "Igual", "Apellido", "ocupado@test.com", "ROLE_ALUMNO");

        assertThatThrownBy(() -> adminService.editarUsuario(segundo.id(), editReq))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("email");
    }

    @Test
    @DisplayName("Editar usuario con DNI de otro usuario lanza excepcion")
    void editar_usuario_dni_duplicado_lanza_excepcion() {
        adminService.crearUsuario(crearRequest("AD000013M", "dnidup1@test.com", "ROLE_ALUMNO"));
        UsuarioResponse segundo = adminService.crearUsuario(
                crearRequest("AD000014N", "dnidup2@test.com", "ROLE_ALUMNO"));

        UpdateUsuarioRequest editReq = new UpdateUsuarioRequest(
                "AD000013M", "Test", "Apellido", "dnidup2@test.com", "ROLE_ALUMNO");

        assertThatThrownBy(() -> adminService.editarUsuario(segundo.id(), editReq))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("DNI");
    }

    @Test
    @DisplayName("Editar usuario con rol invalido lanza excepcion")
    void editar_usuario_rol_invalido() {
        UsuarioResponse creado = adminService.crearUsuario(
                crearRequest("AD000015O", "rolmalo@test.com", "ROLE_ALUMNO"));

        UpdateUsuarioRequest editReq = new UpdateUsuarioRequest(
                "AD000015O", "Test", "Apellido", "rolmalo@test.com", "ROLE_DIOS");

        assertThatThrownBy(() -> adminService.editarUsuario(creado.id(), editReq))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Rol no válido");
    }
}
