package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.models.dto.LoginRequest;
import com.tfg.api.models.dto.RegisterRequest;
import com.tfg.api.models.entity.Rol;
import com.tfg.api.models.repository.RolRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * [A07] Verifica la prevención de account enumeration en AuthServiceImpl.
 */
@SpringBootTest
@Transactional
@ActiveProfiles("test")
class AuthServiceOwaspTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private RolRepository rolRepository;

    @BeforeEach
    void setUp() {
        // La H2 de test arranca vacía (Flyway desactivado): necesitamos el rol base
        if (rolRepository.findByNombre("ROLE_ALUMNO").isEmpty()) {
            rolRepository.save(Rol.builder().nombre("ROLE_ALUMNO").build());
        }
    }

    private RegisterRequest alumno(String dni, String email) {
        return new RegisterRequest(dni, "Test", "Usuario", email, "Password123");
    }

    // ---- Account enumeration en registro ----

    @Test
    @DisplayName("[A07] Email duplicado lanza mensaje genérico que no revela el campo que falló")
    void duplicate_email_returns_generic_message() {
        authService.registrar(alumno("AE000001A", "duplicado@nexus.edu"));

        assertThatThrownBy(() ->
            authService.registrar(alumno("AE000002B", "duplicado@nexus.edu"))
        )
        .isInstanceOf(BusinessRuleException.class)
        .satisfies(ex -> {
            assertThat(ex.getMessage())
                    .doesNotContainIgnoringCase("correo")
                    .doesNotContainIgnoringCase("email")
                    .doesNotContainIgnoringCase("registrado")
                    .isEqualTo("Los datos introducidos no están disponibles. Comprueba el formulario.");
        });
    }

    @Test
    @DisplayName("[A07] DNI duplicado devuelve el mismo mensaje que email duplicado — no distinguible")
    void duplicate_dni_returns_identical_message_to_duplicate_email() {
        authService.registrar(alumno("AE000003C", "original@nexus.edu"));

        assertThatThrownBy(() ->
            authService.registrar(alumno("AE000003C", "diferente@nexus.edu"))
        )
        .isInstanceOf(BusinessRuleException.class)
        .satisfies(ex -> {
            assertThat(ex.getMessage())
                    .doesNotContainIgnoringCase("dni")
                    .doesNotContainIgnoringCase("existe")
                    .isEqualTo("Los datos introducidos no están disponibles. Comprueba el formulario.");
        });
    }

    @Test
    @DisplayName("[A07] Mensaje de email duplicado === mensaje de DNI duplicado (sin distinción)")
    void email_and_dni_duplicate_messages_are_identical() {
        authService.registrar(alumno("AE000004D", "emaildup@nexus.edu"));
        authService.registrar(alumno("AE000005E", "dnidup@nexus.edu"));

        String msgEmail = null;
        String msgDni = null;

        try {
            authService.registrar(alumno("AE000006F", "emaildup@nexus.edu")); // email dup
        } catch (BusinessRuleException e) {
            msgEmail = e.getMessage();
        }

        try {
            authService.registrar(alumno("AE000005E", "unique@nexus.edu")); // DNI dup
        } catch (BusinessRuleException e) {
            msgDni = e.getMessage();
        }

        assertThat(msgEmail).isNotNull();
        assertThat(msgDni).isNotNull();
        assertThat(msgEmail).isEqualTo(msgDni);
    }

    // ---- Account enumeration en login ----

    @Test
    @DisplayName("[A07] Login con usuario inexistente lanza BadCredentialsException, no ResourceNotFoundException con el email")
    void login_unknown_user_throws_bad_credentials_not_resource_not_found() {
        assertThatThrownBy(() ->
            authService.login(new LoginRequest("noexiste@nexus.edu", "cualquier"))
        )
        .isInstanceOf(BadCredentialsException.class)
        .satisfies(ex ->
            assertThat(ex.getMessage())
                    .doesNotContain("noexiste@nexus.edu")
                    .doesNotContainIgnoringCase("email")
        );
    }

    @Test
    @DisplayName("[A07] Login con contraseña incorrecta lanza BadCredentialsException con mensaje genérico")
    void login_wrong_password_returns_generic_message() {
        authService.registrar(alumno("AE000007G", "conocido@nexus.edu"));

        assertThatThrownBy(() ->
            authService.login(new LoginRequest("conocido@nexus.edu", "wrongpassword"))
        )
        .isInstanceOf(BadCredentialsException.class)
        .satisfies(ex ->
            assertThat(ex.getMessage()).doesNotContain("conocido@nexus.edu")
        );
    }
}
