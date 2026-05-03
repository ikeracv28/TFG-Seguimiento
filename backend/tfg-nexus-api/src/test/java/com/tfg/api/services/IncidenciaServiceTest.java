package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class IncidenciaServiceTest {

    @Autowired private IncidenciaService incidenciaService;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private Usuario alumno;
    private Usuario tutorCentro;

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("IN000001A").nombre("Alumno").apellidos("Incidencia")
                .email("alumno.inc@test.com").passwordHash("hash").activo(true).build());
        tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("IN000002B").nombre("Tutor").apellidos("Centro")
                .email("tutor.centro.inc@test.com").passwordHash("hash").activo(true).build());
        Usuario tutorE = usuarioRepository.save(Usuario.builder()
                .dni("IN000003C").nombre("Tutor").apellidos("Empresa")
                .email("tutor.empresa.inc@test.com").passwordHash("hash").activo(true).build());
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("EmpresaInc").cif("B99900002").build());
        practica = practicaRepository.save(Practica.builder()
                .codigo("INC-001").alumno(alumno).tutorCentro(tutorCentro)
                .tutorEmpresa(tutorE).empresa(empresa).estado("ACTIVA").build());

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(alumno.getEmail(), null, Collections.emptyList()));
    }

    @Test
    @DisplayName("Alumno puede crear una incidencia en su practica activa")
    void alumno_puede_crear_incidencia() {
        IncidenciaRequest req = new IncidenciaRequest("ACCIDENTE", "Descripcion detallada del accidente ocurrido");
        IncidenciaResponse resp = incidenciaService.crear(req, alumno.getEmail());

        assertThat(resp.id()).isNotNull();
        assertThat(resp.estado()).isEqualTo("ABIERTA");
        assertThat(resp.tipo()).isEqualTo("ACCIDENTE");
    }

    @Test
    @DisplayName("Usuario sin practica activa no puede crear incidencia")
    void usuario_sin_practica_activa_no_puede_crear() {
        Usuario otroAlumno = usuarioRepository.save(Usuario.builder()
                .dni("IN000004D").nombre("Sin").apellidos("Practica")
                .email("sin.practica@test.com").passwordHash("hash").activo(true).build());

        assertThatThrownBy(() ->
            incidenciaService.crear(new IncidenciaRequest("OTRO", "Sin practica activa asignada"), otroAlumno.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("práctica activa");
    }

    @Test
    @DisplayName("Tutor de centro puede avanzar estado de ABIERTA a EN_PROCESO")
    void tutor_puede_avanzar_estado_a_en_proceso() {
        IncidenciaResponse creada = incidenciaService.crear(
                new IncidenciaRequest("CONFLICTO", "Descripcion del conflicto laboral entre partes"),
                alumno.getEmail());

        IncidenciaResponse actualizada = incidenciaService.actualizarEstado(
                creada.id(), "EN_PROCESO", tutorCentro.getEmail());

        assertThat(actualizada.estado()).isEqualTo("EN_PROCESO");
    }

    @Test
    @DisplayName("Tutor puede cerrar una incidencia pasando por todos los estados")
    void tutor_puede_cerrar_incidencia_completa() {
        IncidenciaResponse creada = incidenciaService.crear(
                new IncidenciaRequest("OTRO", "Descripcion completa del problema reportado"), alumno.getEmail());

        incidenciaService.actualizarEstado(creada.id(), "EN_PROCESO", tutorCentro.getEmail());
        incidenciaService.actualizarEstado(creada.id(), "RESUELTA", tutorCentro.getEmail());
        IncidenciaResponse cerrada = incidenciaService.actualizarEstado(
                creada.id(), "CERRADA", tutorCentro.getEmail());

        assertThat(cerrada.estado()).isEqualTo("CERRADA");
    }

    @Test
    @DisplayName("No se puede retroceder el estado de una incidencia")
    void no_puede_retroceder_estado() {
        IncidenciaResponse creada = incidenciaService.crear(
                new IncidenciaRequest("ACCIDENTE", "Accidente con retroceso de estado"), alumno.getEmail());
        incidenciaService.actualizarEstado(creada.id(), "EN_PROCESO", tutorCentro.getEmail());

        assertThatThrownBy(() ->
            incidenciaService.actualizarEstado(creada.id(), "ABIERTA", tutorCentro.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("retroceder");
    }

    @Test
    @DisplayName("No se puede modificar una incidencia cerrada")
    void no_puede_modificar_incidencia_cerrada() {
        IncidenciaResponse creada = incidenciaService.crear(
                new IncidenciaRequest("CONFLICTO", "Descripcion del conflicto que se cerrara"), alumno.getEmail());
        incidenciaService.actualizarEstado(creada.id(), "EN_PROCESO", tutorCentro.getEmail());
        incidenciaService.actualizarEstado(creada.id(), "RESUELTA", tutorCentro.getEmail());
        incidenciaService.actualizarEstado(creada.id(), "CERRADA", tutorCentro.getEmail());

        assertThatThrownBy(() ->
            incidenciaService.actualizarEstado(creada.id(), "EN_PROCESO", tutorCentro.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("cerrada");
    }

    @Test
    @DisplayName("Estado invalido lanza excepcion")
    void estado_invalido_lanza_excepcion() {
        IncidenciaResponse creada = incidenciaService.crear(
                new IncidenciaRequest("OTRO", "Descripcion con estado invalido para testear"), alumno.getEmail());

        assertThatThrownBy(() ->
            incidenciaService.actualizarEstado(creada.id(), "FANTASMA", tutorCentro.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("no válido");
    }

    @Test
    @DisplayName("Listar incidencias de una practica devuelve las correctas")
    void listar_incidencias_por_practica() {
        incidenciaService.crear(new IncidenciaRequest("ACCIDENTE", "Primera incidencia de lista"), alumno.getEmail());
        incidenciaService.crear(new IncidenciaRequest("CONFLICTO", "Segunda incidencia de lista"), alumno.getEmail());

        List<IncidenciaResponse> lista = incidenciaService.listarPorPractica(practica.getId());

        assertThat(lista).hasSize(2);
    }
}
