package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class PracticaServiceTest {

    @Autowired private PracticaService practicaService;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Usuario alumno;
    private Usuario tutorCentro;
    private Usuario tutorEmpresa;
    private Empresa empresa;

    private void setSecurityContext(String email, String role) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null,
                        List.of(new SimpleGrantedAuthority(role))));
    }

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("11111111A").nombre("Carlos").apellidos("García")
                .email("alumno@practica.com").passwordHash("hash").activo(true).build());
        tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("22222222B").nombre("Ana").apellidos("López")
                .email("tutor.centro@practica.com").passwordHash("hash").activo(true).build());
        tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("33333333C").nombre("Luis").apellidos("Martínez")
                .email("tutor.empresa@practica.com").passwordHash("hash").activo(true).build());
        empresa = empresaRepository.save(Empresa.builder()
                .nombre("Empresa Test").cif("B11111111").build());
    }

    private PracticaRequest buildRequest(String codigo) {
        return new PracticaRequest(codigo, alumno.getId(), tutorCentro.getId(),
                tutorEmpresa.getId(), empresa.getId(),
                LocalDate.now(), LocalDate.now().plusMonths(3), 400, "BORRADOR");
    }

    // ─── crear ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("crear guarda una nueva práctica correctamente")
    void crear_practica_correctamente() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");

        PracticaResponse resp = practicaService.crear(buildRequest("PRAC-001"));

        assertThat(resp.id()).isNotNull();
        assertThat(resp.codigo()).isEqualTo("PRAC-001");
    }

    @Test
    @DisplayName("crear lanza excepción si código ya existe")
    void crear_codigo_duplicado_lanza_excepcion() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        practicaService.crear(buildRequest("PRAC-DUP"));

        assertThatThrownBy(() -> practicaService.crear(buildRequest("PRAC-DUP")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("PRAC-DUP");
    }

    @Test
    @DisplayName("crear lanza excepción si el alumno no existe")
    void crear_alumno_inexistente_lanza_excepcion() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaRequest req = new PracticaRequest("PRAC-X", 999999L, tutorCentro.getId(),
                tutorEmpresa.getId(), empresa.getId(), null, null, null, null);

        assertThatThrownBy(() -> practicaService.crear(req))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── obtenerPorId ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("obtenerPorId devuelve la práctica existente")
    void obtener_por_id_existente() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-GET"));

        PracticaResponse encontrada = practicaService.obtenerPorId(creada.id());
        assertThat(encontrada.codigo()).isEqualTo("PRAC-GET");
    }

    @Test
    @DisplayName("obtenerPorId lanza excepción si no existe")
    void obtener_por_id_inexistente_lanza_excepcion() {
        assertThatThrownBy(() -> practicaService.obtenerPorId(999999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── listarTodas ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("listarTodas devuelve página con las prácticas creadas")
    void listar_todas_con_pageable() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        practicaService.crear(buildRequest("PRAC-LIST1"));
        practicaService.crear(buildRequest("PRAC-LIST2"));

        Page<PracticaResponse> page = practicaService.listarTodas(PageRequest.of(0, 10));
        assertThat(page.getTotalElements()).isGreaterThanOrEqualTo(2);
    }

    // ─── listarPorAlumno ─────────────────────────────────────────────────────

    @Test
    @DisplayName("listarPorAlumno devuelve solo prácticas del alumno indicado")
    void listar_por_alumno() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        practicaService.crear(buildRequest("PRAC-A1"));
        practicaService.crear(buildRequest("PRAC-A2"));

        List<PracticaResponse> lista = practicaService.listarPorAlumno(alumno.getId());
        assertThat(lista).hasSize(2);
        assertThat(lista).allMatch(p -> p.alumnoNombre() != null);
    }

    // ─── actualizar ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("actualizar modifica los campos de una práctica existente")
    void actualizar_practica() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-UPD"));

        PracticaRequest updateReq = new PracticaRequest("PRAC-UPD-MOD", alumno.getId(),
                tutorCentro.getId(), tutorEmpresa.getId(), empresa.getId(),
                LocalDate.now(), LocalDate.now().plusMonths(6), 600, "ACTIVA");
        PracticaResponse actualizada = practicaService.actualizar(creada.id(), updateReq);

        assertThat(actualizada.codigo()).isEqualTo("PRAC-UPD-MOD");
        assertThat(actualizada.horasTotales()).isEqualTo(600);
    }

    @Test
    @DisplayName("actualizar lanza excepción si la práctica no existe")
    void actualizar_inexistente_lanza_excepcion() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        assertThatThrownBy(() -> practicaService.actualizar(999999L, buildRequest("X")))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── eliminar ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("eliminar borra una práctica en estado BORRADOR")
    void eliminar_practica_borrador() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-DEL"));
        Long id = creada.id();

        practicaService.eliminar(id);

        assertThat(practicaRepository.existsById(id)).isFalse();
    }

    @Test
    @DisplayName("eliminar lanza excepción si la práctica está ACTIVA")
    void eliminar_practica_activa_lanza_excepcion() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-NO-DEL"));
        practicaService.cambiarEstado(creada.id(), "ACTIVA");

        assertThatThrownBy(() -> practicaService.eliminar(creada.id()))
                .isInstanceOf(BusinessRuleException.class);
    }

    // ─── cambiarEstado ────────────────────────────────────────────────────────

    @Test
    @DisplayName("cambiarEstado a ACTIVA funciona correctamente")
    void cambiar_estado_a_activa() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-EST"));

        PracticaResponse actualizada = practicaService.cambiarEstado(creada.id(), "ACTIVA");
        assertThat(actualizada.estado()).isEqualTo("ACTIVA");
    }

    @Test
    @DisplayName("cambiarEstado con estado inválido lanza excepción")
    void cambiar_estado_invalido_lanza_excepcion() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-BAD"));

        assertThatThrownBy(() -> practicaService.cambiarEstado(creada.id(), "INVENTADO"))
                .isInstanceOf(BusinessRuleException.class);
    }

    // ─── obtenerPracticaActivaDelAlumno ──────────────────────────────────────

    @Test
    @DisplayName("obtenerPracticaActivaDelAlumno devuelve la práctica activa")
    void obtener_practica_activa_del_alumno() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-ACT"));
        practicaService.cambiarEstado(creada.id(), "ACTIVA");

        setSecurityContext("alumno@practica.com", "ROLE_ALUMNO");
        PracticaResponse activa = practicaService.obtenerPracticaActivaDelAlumno();

        assertThat(activa.estado()).isEqualTo("ACTIVA");
    }

    @Test
    @DisplayName("obtenerPracticaActivaDelAlumno lanza excepción si no hay práctica activa")
    void obtener_practica_activa_sin_practica_lanza_excepcion() {
        setSecurityContext("alumno@practica.com", "ROLE_ALUMNO");

        assertThatThrownBy(() -> practicaService.obtenerPracticaActivaDelAlumno())
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── listarMisPracticasComoTutorEmpresa/Centro ────────────────────────────

    @Test
    @DisplayName("listarMisPracticasComoTutorEmpresa devuelve prácticas del tutor")
    void listar_mis_practicas_tutor_empresa() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        practicaService.crear(buildRequest("PRAC-TE1"));
        practicaService.crear(buildRequest("PRAC-TE2"));

        setSecurityContext("tutor.empresa@practica.com", "ROLE_TUTOR_EMPRESA");
        List<PracticaResponse> lista = practicaService.listarMisPracticasComoTutorEmpresa();

        assertThat(lista).hasSize(2);
    }

    @Test
    @DisplayName("listarMisPracticasComoTutorCentro devuelve prácticas del tutor")
    void listar_mis_practicas_tutor_centro() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        practicaService.crear(buildRequest("PRAC-TC1"));

        setSecurityContext("tutor.centro@practica.com", "ROLE_TUTOR_CENTRO");
        List<PracticaResponse> lista = practicaService.listarMisPracticasComoTutorCentro();

        assertThat(lista).hasSize(1);
    }

    // ─── esParticipante / perteneceAlAlumnoAutenticado ────────────────────────

    @Test
    @DisplayName("esParticipante devuelve true para el alumno de la práctica")
    void es_participante_alumno() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-PART"));

        boolean result = practicaService.esParticipante(creada.id(), "alumno@practica.com");
        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("esParticipante devuelve false para usuario ajeno")
    void es_participante_ajeno_false() {
        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        PracticaResponse creada = practicaService.crear(buildRequest("PRAC-PART2"));

        boolean result = practicaService.esParticipante(creada.id(), "ajeno@test.com");
        assertThat(result).isFalse();
    }
}
