package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.models.repository.IncidenciaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
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
class SeguimientoDoubleValidationTest {

    @Autowired private SeguimientoService seguimientoService;
    @Autowired private IncidenciaRepository incidenciaRepository;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private static final String EMAIL_TUTOR_EMPRESA = "tutorempresa@validacion.test";
    private static final String EMAIL_TUTOR_CENTRO  = "tutorcentro@validacion.test";

    @BeforeEach
    void setUp() {
        Usuario alumno = usuarioRepository.save(Usuario.builder()
                .dni("10000001A").nombre("Alumno").apellidos("Validacion")
                .email("alumno@validacion.test").passwordHash("hash").activo(true).build());
        Usuario tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("10000002B").nombre("Tutor").apellidos("Centro")
                .email(EMAIL_TUTOR_CENTRO).passwordHash("hash").activo(true).build());
        Usuario tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("10000003C").nombre("Tutor").apellidos("Empresa")
                .email(EMAIL_TUTOR_EMPRESA).passwordHash("hash").activo(true).build());
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("Empresa Validacion").cif("B99999999").build());

        practica = practicaRepository.save(Practica.builder()
                .codigo("VAL-001").alumno(alumno).tutorCentro(tutorCentro)
                .tutorEmpresa(tutorEmpresa).empresa(empresa).estado("ACTIVA").build());
    }

    // ------------------------------------------------------------------ //
    // CASO 1: Alumno registra parte → estado PENDIENTE_EMPRESA            //
    // ------------------------------------------------------------------ //
    @Test
    @DisplayName("Caso 1: alumno registra parte, estado inicial es PENDIENTE_EMPRESA")
    void caso1_registro_estado_pendiente_empresa() {
        SeguimientoResponse response = seguimientoService.registrar(
                new SeguimientoRequest(practica.getId(), LocalDate.now(), 8, "Primera semana"));

        assertThat(response.estado()).isEqualTo("PENDIENTE_EMPRESA");
    }

    // ------------------------------------------------------------------ //
    // CASO 2: Tutor empresa aprueba → PENDIENTE_CENTRO                    //
    // ------------------------------------------------------------------ //
    @Test
    @DisplayName("Caso 2: tutor empresa valida parte, estado pasa a PENDIENTE_CENTRO")
    void caso2_tutor_empresa_valida() {
        SeguimientoResponse reg = seguimientoService.registrar(
                new SeguimientoRequest(practica.getId(), LocalDate.now(), 8, "Segunda semana"));

        setSecurityContext(EMAIL_TUTOR_EMPRESA);
        SeguimientoResponse result = seguimientoService.validarEmpresa(reg.id(), "PENDIENTE_CENTRO", null);

        assertThat(result.estado()).isEqualTo("PENDIENTE_CENTRO");
        assertThat(result.validadoPorNombre()).contains("Tutor Empresa");
    }

    // ------------------------------------------------------------------ //
    // CASO 3: Tutor empresa rechaza → RECHAZADO + incidencia automática   //
    // ------------------------------------------------------------------ //
    @Test
    @DisplayName("Caso 3: tutor empresa rechaza parte, se genera incidencia RECHAZO_PARTE automáticamente")
    void caso3_tutor_empresa_rechaza_genera_incidencia() {
        SeguimientoResponse reg = seguimientoService.registrar(
                new SeguimientoRequest(practica.getId(), LocalDate.now(), 8, "Tercera semana"));

        long incidenciasPrevias = incidenciaRepository.count();

        setSecurityContext(EMAIL_TUTOR_EMPRESA);
        SeguimientoResponse result = seguimientoService.validarEmpresa(
                reg.id(), "RECHAZADO", "Las horas no coinciden con el registro de la empresa");

        assertThat(result.estado()).isEqualTo("RECHAZADO");
        assertThat(result.comentarioTutor()).contains("Las horas no coinciden");
        assertThat(incidenciaRepository.count()).isEqualTo(incidenciasPrevias + 1);

        var incidenciaCreada = incidenciaRepository
                .findByPracticaIdOrderByFechaCreacionDesc(practica.getId()).get(0);
        assertThat(incidenciaCreada.getTipo()).isEqualTo("RECHAZO_PARTE");
        assertThat(incidenciaCreada.getEstado()).isEqualTo("ABIERTA");
    }

    // ------------------------------------------------------------------ //
    // CASO 4: Tutor centro salta el orden → BusinessRuleException          //
    // ------------------------------------------------------------------ //
    @Test
    @DisplayName("Caso 4: tutor centro no puede validar un parte que aún está en PENDIENTE_EMPRESA")
    void caso4_tutor_centro_no_puede_saltarse_el_orden() {
        SeguimientoResponse reg = seguimientoService.registrar(
                new SeguimientoRequest(practica.getId(), LocalDate.now(), 8, "Cuarta semana"));

        setSecurityContext(EMAIL_TUTOR_CENTRO);
        assertThatThrownBy(() -> seguimientoService.validarCentro(reg.id()))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("debe ser validado por la empresa");
    }

    // ------------------------------------------------------------------ //
    // FLUJO COMPLETO: empresa → centro → COMPLETADO                       //
    // ------------------------------------------------------------------ //
    @Test
    @DisplayName("Flujo completo: empresa valida y centro completa, estado final es COMPLETADO")
    void flujo_completo_empresa_luego_centro() {
        SeguimientoResponse reg = seguimientoService.registrar(
                new SeguimientoRequest(practica.getId(), LocalDate.now(), 8, "Quinta semana"));

        setSecurityContext(EMAIL_TUTOR_EMPRESA);
        seguimientoService.validarEmpresa(reg.id(), "PENDIENTE_CENTRO", null);

        setSecurityContext(EMAIL_TUTOR_CENTRO);
        SeguimientoResponse completado = seguimientoService.validarCentro(reg.id());

        assertThat(completado.estado()).isEqualTo("COMPLETADO");
        assertThat(completado.validadoPorNombre()).contains("Tutor Centro");
    }

    private void setSecurityContext(String email) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, List.of()));
    }
}
