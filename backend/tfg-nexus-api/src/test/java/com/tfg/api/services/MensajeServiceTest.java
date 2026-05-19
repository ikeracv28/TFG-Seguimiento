package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.MensajeRequest;
import com.tfg.api.models.dto.MensajeResponse;
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

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class MensajeServiceTest {

    @Autowired private MensajeService mensajeService;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private Usuario alumno;
    private Usuario tutorCentro;
    private Usuario tutorEmpresa;

    private static final String CANAL_ALUMNO   = "ALUMNO";
    private static final String CANAL_TUTORES  = "TUTORES";

    private void setSecurityContext(String email) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, List.of()));
    }

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("MS000001A").nombre("Alumno").apellidos("Chat")
                .email("alumno.chat@test.com").passwordHash("hash").activo(true).build());
        tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("MS000002B").nombre("Tutor").apellidos("Centro")
                .email("tutor.centro.chat@test.com").passwordHash("hash").activo(true).build());
        tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("MS000003C").nombre("Tutor").apellidos("Empresa")
                .email("tutor.empresa.chat@test.com").passwordHash("hash").activo(true).build());
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("EmpresaChat").cif("B12312312").build());
        practica = practicaRepository.save(Practica.builder()
                .codigo("CHAT-001").alumno(alumno).tutorCentro(tutorCentro)
                .tutorEmpresa(tutorEmpresa).empresa(empresa).estado("ACTIVA").build());
    }

    // ── Canal ALUMNO ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("Alumno puede enviar un mensaje en canal ALUMNO")
    void alumno_puede_enviar_mensaje() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Hola tutor", CANAL_ALUMNO),
                alumno.getEmail(), practica.getId(), CANAL_ALUMNO);

        assertThat(resp.id()).isNotNull();
        assertThat(resp.contenido()).isEqualTo("Hola tutor");
        assertThat(resp.practicaId()).isEqualTo(practica.getId());
        assertThat(resp.remitenteId()).isEqualTo(alumno.getId());
        assertThat(resp.canal()).isEqualTo(CANAL_ALUMNO);
    }

    @Test
    @DisplayName("Tutor de centro puede enviar mensaje en canal ALUMNO")
    void tutor_centro_puede_enviar_mensaje_alumno() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Revisad el parte", CANAL_ALUMNO),
                tutorCentro.getEmail(), practica.getId(), CANAL_ALUMNO);

        assertThat(resp.remitenteId()).isEqualTo(tutorCentro.getId());
        assertThat(resp.contenido()).isEqualTo("Revisad el parte");
    }

    @Test
    @DisplayName("Tutor empresa no puede usar canal ALUMNO — BusinessRuleException")
    void tutor_empresa_no_puede_usar_canal_alumno() {
        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Hola", CANAL_ALUMNO),
                    tutorEmpresa.getEmail(), practica.getId(), CANAL_ALUMNO)
        ).isInstanceOf(BusinessRuleException.class);
    }

    // ── Canal TUTORES ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("Tutor empresa puede enviar mensaje en canal TUTORES")
    void tutor_empresa_puede_enviar_mensaje_tutores() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Aprobado el parte", CANAL_TUTORES),
                tutorEmpresa.getEmail(), practica.getId(), CANAL_TUTORES);

        assertThat(resp.remitenteId()).isEqualTo(tutorEmpresa.getId());
        assertThat(resp.canal()).isEqualTo(CANAL_TUTORES);
    }

    @Test
    @DisplayName("Tutor centro puede enviar mensaje en canal TUTORES")
    void tutor_centro_puede_enviar_mensaje_tutores() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Confirmado", CANAL_TUTORES),
                tutorCentro.getEmail(), practica.getId(), CANAL_TUTORES);

        assertThat(resp.remitenteId()).isEqualTo(tutorCentro.getId());
        assertThat(resp.canal()).isEqualTo(CANAL_TUTORES);
    }

    @Test
    @DisplayName("Alumno no puede usar canal TUTORES — BusinessRuleException")
    void alumno_no_puede_usar_canal_tutores() {
        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Infiltrado", CANAL_TUTORES),
                    alumno.getEmail(), practica.getId(), CANAL_TUTORES)
        ).isInstanceOf(BusinessRuleException.class);
    }

    // ── Listado ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Listar canal ALUMNO devuelve solo mensajes de ese canal")
    void listar_canal_alumno_sin_mensajes() {
        setSecurityContext(alumno.getEmail());
        List<MensajeResponse> mensajes = mensajeService.listarPorPractica(practica.getId(), CANAL_ALUMNO);
        assertThat(mensajes).isEmpty();
    }

    @Test
    @DisplayName("Mensajes de canales distintos no se mezclan")
    void mensajes_canales_no_se_mezclan() {
        mensajeService.guardar(new MensajeRequest("Mensaje alumno", CANAL_ALUMNO),
                alumno.getEmail(), practica.getId(), CANAL_ALUMNO);
        mensajeService.guardar(new MensajeRequest("Mensaje tutores", CANAL_TUTORES),
                tutorEmpresa.getEmail(), practica.getId(), CANAL_TUTORES);

        setSecurityContext(alumno.getEmail());
        List<MensajeResponse> canalAlumno = mensajeService.listarPorPractica(practica.getId(), CANAL_ALUMNO);
        assertThat(canalAlumno).hasSize(1);
        assertThat(canalAlumno.get(0).contenido()).isEqualTo("Mensaje alumno");

        setSecurityContext(tutorCentro.getEmail());
        List<MensajeResponse> canalTutores = mensajeService.listarPorPractica(practica.getId(), CANAL_TUTORES);
        assertThat(canalTutores).hasSize(1);
        assertThat(canalTutores.get(0).contenido()).isEqualTo("Mensaje tutores");
    }

    @Test
    @DisplayName("Listar mensajes devuelve en orden cronológico ascendente")
    void listar_mensajes_orden_cronologico() {
        mensajeService.guardar(new MensajeRequest("Primer mensaje", CANAL_ALUMNO),
                alumno.getEmail(), practica.getId(), CANAL_ALUMNO);
        mensajeService.guardar(new MensajeRequest("Segundo mensaje", CANAL_ALUMNO),
                tutorCentro.getEmail(), practica.getId(), CANAL_ALUMNO);

        setSecurityContext(alumno.getEmail());
        List<MensajeResponse> mensajes = mensajeService.listarPorPractica(practica.getId(), CANAL_ALUMNO);

        assertThat(mensajes).hasSize(2);
        assertThat(mensajes.get(0).contenido()).isEqualTo("Primer mensaje");
        assertThat(mensajes.get(1).contenido()).isEqualTo("Segundo mensaje");
    }

    @Test
    @DisplayName("La respuesta incluye nombre, apellidos y fechaEnvio del remitente")
    void respuesta_incluye_datos_del_remitente() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Comprobar datos", CANAL_ALUMNO),
                alumno.getEmail(), practica.getId(), CANAL_ALUMNO);

        assertThat(resp.remitenteNombre()).isEqualTo("Alumno");
        assertThat(resp.remitenteApellidos()).isEqualTo("Chat");
        assertThat(resp.fechaEnvio()).isNotNull();
    }

    @Test
    @DisplayName("Práctica inexistente lanza ResourceNotFoundException")
    void practica_inexistente_lanza_excepcion() {
        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Sin práctica", CANAL_ALUMNO),
                    alumno.getEmail(), 999999L, CANAL_ALUMNO)
        ).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("Usuario ajeno a la práctica no puede enviar mensajes — BusinessRuleException")
    void ajeno_no_puede_enviar_mensaje() {
        Usuario ajeno = usuarioRepository.save(Usuario.builder()
                .dni("MS000004D").nombre("Externo").apellidos("Ajeno")
                .email("externo.chat@test.com").passwordHash("hash").activo(true).build());

        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Intento no autorizado", CANAL_ALUMNO),
                    ajeno.getEmail(), practica.getId(), CANAL_ALUMNO)
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("acceso");
    }
}
