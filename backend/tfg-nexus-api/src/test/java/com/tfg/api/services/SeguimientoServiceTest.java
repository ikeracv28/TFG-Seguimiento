package com.tfg.api.services;

import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
@org.springframework.test.context.ActiveProfiles("test")
class SeguimientoServiceTest {

    @Autowired
    private SeguimientoService seguimientoService;

    @Autowired
    private PracticaRepository practicaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private EmpresaRepository empresaRepository;

    private Practica practicaTest;

    @BeforeEach
    void setUp() {
        // Creamos datos mínimos para la prueba
        Usuario alumno = usuarioRepository.save(Usuario.builder()
                .dni("11111111A").nombre("Alumno").apellidos("Test").email("alumno@test.com").passwordHash("hash").activo(true).build());
        Usuario tutorC = usuarioRepository.save(Usuario.builder()
                .dni("22222222B").nombre("Tutor").apellidos("Centro").email("tutor@test.com").passwordHash("hash").activo(true).build());
        Usuario tutorE = usuarioRepository.save(Usuario.builder()
                .dni("33333333C").nombre("Tutor").apellidos("Empresa").email("empresa@test.com").passwordHash("hash").activo(true).build());
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("Empresa Test").cif("B12345678").build());

        practicaTest = practicaRepository.save(Practica.builder()
                .codigo("TEST-001").alumno(alumno).tutorCentro(tutorC).tutorEmpresa(tutorE).empresa(empresa).estado("ACTIVA").build());
    }

    @Test
    @DisplayName("Debe registrar un seguimiento correctamente")
    void should_register_seguimiento() {
        SeguimientoRequest request = new SeguimientoRequest(
                practicaTest.getId(), LocalDate.now(), 4, "Tareas de desarrollo"
        );

        SeguimientoResponse response = seguimientoService.registrar(request);

        assertThat(response.id()).isNotNull();
        assertThat(response.horasRealizadas()).isEqualTo(4);
        assertThat(response.estado()).isEqualTo("PENDIENTE");
    }

    @Test
    @WithMockUser(username = "tutor@test.com")
    @DisplayName("Debe permitir validar un seguimiento a un tutor")
    void should_validate_seguimiento() {
        // Primero registramos uno
        SeguimientoResponse reg = seguimientoService.registrar(new SeguimientoRequest(
                practicaTest.getId(), LocalDate.now(), 6, "Pruebas unitarias"
        ));

        // Validamos
        SeguimientoResponse validated = seguimientoService.validar(reg.id(), "VALIDADO", "Buen trabajo");

        assertThat(validated.estado()).isEqualTo("VALIDADO");
        assertThat(validated.comentarioTutor()).isEqualTo("Buen trabajo");
        assertThat(validated.validadoPorNombre()).contains("Tutor Centro");
    }
}
