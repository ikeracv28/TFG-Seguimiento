package com.tfg.api.services;

import com.tfg.api.models.dto.EvaluacionFinalRequest;
import com.tfg.api.models.dto.EvaluacionFinalResponse;
import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.models.repository.EvaluacionFinalRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class EvaluacionFinalServiceTest {

    @Autowired private EvaluacionFinalService evaluacionService;
    @Autowired private EvaluacionFinalRepository evaluacionRepository;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private Usuario alumno;
    private Usuario tutorEmpresa;
    private Usuario tutorCentro;
    private Usuario otroTutor;

    private void setSecurityContext(String email, String... roles) {
        List<SimpleGrantedAuthority> auths = List.of(roles).stream()
                .map(SimpleGrantedAuthority::new)
                .toList();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, auths));
    }

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("11111111A").nombre("Carlos").apellidos("García")
                .email("alumno@eval.com").passwordHash("hash").activo(true).build());
        tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("22222222B").nombre("Ana").apellidos("López")
                .email("tutorcentro@eval.com").passwordHash("hash").activo(true).build());
        tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("33333333C").nombre("Luis").apellidos("Martínez")
                .email("tutorempresa@eval.com").passwordHash("hash").activo(true).build());
        otroTutor = usuarioRepository.save(Usuario.builder()
                .dni("44444444D").nombre("Otro").apellidos("Tutor")
                .email("otro@eval.com").passwordHash("hash").activo(true).build());

        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("Empresa Eval").cif("B87654321").build());

        practica = practicaRepository.save(Practica.builder()
                .codigo("EVAL-001")
                .alumno(alumno)
                .tutorCentro(tutorCentro)
                .tutorEmpresa(tutorEmpresa)
                .empresa(empresa)
                .estado("ACTIVA")
                .build());
    }

    // ─── evaluar ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Tutor empresa puede evaluar con todos los criterios")
    void tutor_empresa_evalua_con_criterios() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");

        EvaluacionFinalRequest req = new EvaluacionFinalRequest(
                BigDecimal.valueOf(8.0), BigDecimal.valueOf(7.5),
                BigDecimal.valueOf(9.0), BigDecimal.valueOf(8.5),
                BigDecimal.valueOf(7.0), BigDecimal.valueOf(8.0),
                "Buen alumno");

        EvaluacionFinalResponse resp = evaluacionService.evaluar(practica.getId(), req);

        assertThat(resp.id()).isNotNull();
        assertThat(resp.notaGlobal()).isEqualByComparingTo(BigDecimal.valueOf(8.0));
        assertThat(resp.actitudPuntualidad()).isEqualByComparingTo(BigDecimal.valueOf(8.0));
        assertThat(resp.comentario()).isEqualTo("Buen alumno");
        assertThat(resp.alumnoNombre()).contains("Carlos");
        assertThat(resp.tutorEmpresaNombre()).contains("Luis");
    }

    @Test
    @DisplayName("Tutor empresa puede evaluar solo con nota global (criterios opcionales)")
    void evaluar_solo_nota_global_es_valido() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");

        EvaluacionFinalRequest req = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(6.5), null);

        EvaluacionFinalResponse resp = evaluacionService.evaluar(practica.getId(), req);

        assertThat(resp.notaGlobal()).isEqualByComparingTo(BigDecimal.valueOf(6.5));
        assertThat(resp.actitudPuntualidad()).isNull();
    }

    @Test
    @DisplayName("Evaluar actualiza (upsert) si ya existe evaluación")
    void evaluar_actualiza_existente() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");

        EvaluacionFinalRequest primera = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(5.0), "Primera");
        evaluacionService.evaluar(practica.getId(), primera);

        EvaluacionFinalRequest segunda = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(8.0), "Actualizada");
        EvaluacionFinalResponse resp = evaluacionService.evaluar(practica.getId(), segunda);

        assertThat(resp.notaGlobal()).isEqualByComparingTo(BigDecimal.valueOf(8.0));
        assertThat(resp.comentario()).isEqualTo("Actualizada");
        // Solo debe existir una evaluación
        assertThat(evaluacionRepository.count()).isEqualTo(1);
    }

    @Test
    @DisplayName("Tutor que no es de esta práctica no puede evaluar — A01 IDOR")
    void tutor_ajeno_no_puede_evaluar() {
        setSecurityContext("otro@eval.com", "ROLE_TUTOR_EMPRESA");

        EvaluacionFinalRequest req = new EvaluacionFinalRequest(
                null, null, null, null, null, BigDecimal.valueOf(7.0), null);

        assertThatThrownBy(() -> evaluacionService.evaluar(practica.getId(), req))
                .isInstanceOf(AccessDeniedException.class);
    }

    // ─── obtenerPorPractica ──────────────────────────────────────────────────

    @Test
    @DisplayName("Alumno puede ver su propia evaluación")
    void alumno_ve_su_evaluacion() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");
        evaluacionService.evaluar(practica.getId(),
                new EvaluacionFinalRequest(null, null, null, null, null, BigDecimal.valueOf(7.0), null));

        setSecurityContext("alumno@eval.com", "ROLE_ALUMNO");
        Optional<EvaluacionFinalResponse> result = evaluacionService.obtenerPorPractica(practica.getId());

        assertThat(result).isPresent();
        assertThat(result.get().notaGlobal()).isEqualByComparingTo(BigDecimal.valueOf(7.0));
    }

    @Test
    @DisplayName("Tutor centro puede ver la evaluación de su práctica")
    void tutor_centro_ve_evaluacion() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");
        evaluacionService.evaluar(practica.getId(),
                new EvaluacionFinalRequest(null, null, null, null, null, BigDecimal.valueOf(9.0), null));

        setSecurityContext("tutorcentro@eval.com", "ROLE_TUTOR_CENTRO");
        Optional<EvaluacionFinalResponse> result = evaluacionService.obtenerPorPractica(practica.getId());

        assertThat(result).isPresent();
    }

    @Test
    @DisplayName("Admin puede ver cualquier evaluación")
    void admin_ve_evaluacion() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");
        evaluacionService.evaluar(practica.getId(),
                new EvaluacionFinalRequest(null, null, null, null, null, BigDecimal.valueOf(6.0), null));

        setSecurityContext("admin@nexus.edu", "ROLE_ADMIN");
        Optional<EvaluacionFinalResponse> result = evaluacionService.obtenerPorPractica(practica.getId());

        assertThat(result).isPresent();
    }

    @Test
    @DisplayName("Devuelve vacío cuando aún no hay evaluación")
    void devuelve_vacio_sin_evaluacion() {
        setSecurityContext("alumno@eval.com", "ROLE_ALUMNO");
        Optional<EvaluacionFinalResponse> result = evaluacionService.obtenerPorPractica(practica.getId());

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Usuario ajeno a la práctica no puede ver la evaluación — A01 IDOR")
    void usuario_ajeno_no_puede_ver_evaluacion() {
        setSecurityContext("tutorempresa@eval.com", "ROLE_TUTOR_EMPRESA");
        evaluacionService.evaluar(practica.getId(),
                new EvaluacionFinalRequest(null, null, null, null, null, BigDecimal.valueOf(7.0), null));

        setSecurityContext("otro@eval.com", "ROLE_TUTOR_EMPRESA");
        assertThatThrownBy(() -> evaluacionService.obtenerPorPractica(practica.getId()))
                .isInstanceOf(AccessDeniedException.class);
    }
}
