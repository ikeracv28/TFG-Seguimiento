package com.tfg.api.services;

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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * [A01] Verifica los métodos de verificación de propiedad en PracticaServiceImpl.
 * Cubre esParticipante() y perteneceAlAlumnoAutenticado() usados en los SpEL de @PreAuthorize.
 */
@SpringBootTest
@Transactional
@ActiveProfiles("test")
class PracticaOwnershipTest {

    @Autowired private PracticaService practicaService;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private Usuario alumno;
    private Usuario tutorCentro;
    private Usuario tutorEmpresa;
    private Usuario outsider;

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("POW001A").nombre("Alumno").apellidos("Test")
                .email("alumno.pow@test.com").passwordHash("hash").activo(true).build());
        tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("POW002B").nombre("TutorC").apellidos("Test")
                .email("tutorc.pow@test.com").passwordHash("hash").activo(true).build());
        tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("POW003C").nombre("TutorE").apellidos("Test")
                .email("tutore.pow@test.com").passwordHash("hash").activo(true).build());
        outsider = usuarioRepository.save(Usuario.builder()
                .dni("POW004D").nombre("Outsider").apellidos("Test")
                .email("outsider.pow@test.com").passwordHash("hash").activo(true).build());

        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("Empresa POW").cif("BPOW12345").build());

        practica = practicaRepository.save(Practica.builder()
                .codigo("POW-001").alumno(alumno).tutorCentro(tutorCentro)
                .tutorEmpresa(tutorEmpresa).empresa(empresa).estado("ACTIVA").build());
    }

    // ---- esParticipante ----

    @Test
    @DisplayName("[A01] esParticipante: true para el alumno propio de la práctica")
    void esParticipante_true_for_alumno() {
        assertThat(practicaService.esParticipante(practica.getId(), "alumno.pow@test.com")).isTrue();
    }

    @Test
    @DisplayName("[A01] esParticipante: true para el tutor del centro asignado")
    void esParticipante_true_for_tutorCentro() {
        assertThat(practicaService.esParticipante(practica.getId(), "tutorc.pow@test.com")).isTrue();
    }

    @Test
    @DisplayName("[A01] esParticipante: true para el tutor de empresa asignado")
    void esParticipante_true_for_tutorEmpresa() {
        assertThat(practicaService.esParticipante(practica.getId(), "tutore.pow@test.com")).isTrue();
    }

    @Test
    @DisplayName("[A01] esParticipante: false para usuario ajeno — bloquea IDOR entre alumnos")
    void esParticipante_false_for_outsider() {
        assertThat(practicaService.esParticipante(practica.getId(), "outsider.pow@test.com")).isFalse();
    }

    @Test
    @DisplayName("[A01] esParticipante: false para práctica que no existe — no hay fuga de información")
    void esParticipante_false_for_nonexistent_practica() {
        assertThat(practicaService.esParticipante(999999L, "alumno.pow@test.com")).isFalse();
    }

    @Test
    @DisplayName("[A01] esParticipante: false para email no registrado")
    void esParticipante_false_for_unknown_email() {
        assertThat(practicaService.esParticipante(practica.getId(), "noexiste@test.com")).isFalse();
    }

    // ---- perteneceAlAlumnoAutenticado ----

    @Test
    @DisplayName("[A01] perteneceAlAlumnoAutenticado: true cuando el email corresponde al alumnoId")
    void perteneceAlAlumno_true_for_owner() {
        assertThat(practicaService.perteneceAlAlumnoAutenticado(alumno.getId(), "alumno.pow@test.com")).isTrue();
    }

    @Test
    @DisplayName("[A01] perteneceAlAlumnoAutenticado: false cuando el email pertenece a otro alumno (fix SpEL roto)")
    void perteneceAlAlumno_false_for_other_user() {
        assertThat(practicaService.perteneceAlAlumnoAutenticado(alumno.getId(), "outsider.pow@test.com")).isFalse();
    }

    @Test
    @DisplayName("[A01] perteneceAlAlumnoAutenticado: false para email no registrado")
    void perteneceAlAlumno_false_for_unknown_email() {
        assertThat(practicaService.perteneceAlAlumnoAutenticado(alumno.getId(), "noexiste@test.com")).isFalse();
    }

    @Test
    @DisplayName("[A01] perteneceAlAlumnoAutenticado: false cuando alumnoId corresponde a otro usuario")
    void perteneceAlAlumno_false_when_id_belongs_to_different_user() {
        assertThat(practicaService.perteneceAlAlumnoAutenticado(tutorCentro.getId(), "alumno.pow@test.com")).isFalse();
    }
}
