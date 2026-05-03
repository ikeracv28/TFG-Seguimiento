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

    @Test
    @DisplayName("Alumno puede enviar un mensaje en su práctica")
    void alumno_puede_enviar_mensaje() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Hola tutor"), alumno.getEmail(), practica.getId());

        assertThat(resp.id()).isNotNull();
        assertThat(resp.contenido()).isEqualTo("Hola tutor");
        assertThat(resp.practicaId()).isEqualTo(practica.getId());
        assertThat(resp.remitenteId()).isEqualTo(alumno.getId());
    }

    @Test
    @DisplayName("Tutor de centro puede enviar mensaje en la práctica")
    void tutor_centro_puede_enviar_mensaje() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Revisad el parte"), tutorCentro.getEmail(), practica.getId());

        assertThat(resp.remitenteId()).isEqualTo(tutorCentro.getId());
        assertThat(resp.contenido()).isEqualTo("Revisad el parte");
    }

    @Test
    @DisplayName("Tutor de empresa puede enviar mensaje en la práctica")
    void tutor_empresa_puede_enviar_mensaje() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Aprobado el parte"), tutorEmpresa.getEmail(), practica.getId());

        assertThat(resp.remitenteId()).isEqualTo(tutorEmpresa.getId());
    }

    @Test
    @DisplayName("Usuario ajeno a la práctica no puede enviar mensajes — BusinessRuleException")
    void ajeno_no_puede_enviar_mensaje() {
        Usuario ajeno = usuarioRepository.save(Usuario.builder()
                .dni("MS000004D").nombre("Externo").apellidos("Ajeno")
                .email("externo.chat@test.com").passwordHash("hash").activo(true).build());

        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Intento no autorizado"),
                    ajeno.getEmail(), practica.getId())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("acceso");
    }

    @Test
    @DisplayName("Práctica inexistente lanza ResourceNotFoundException")
    void practica_inexistente_lanza_excepcion() {
        assertThatThrownBy(() ->
            mensajeService.guardar(new MensajeRequest("Sin práctica"),
                    alumno.getEmail(), 999999L)
        ).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("Listar mensajes de práctica sin mensajes devuelve lista vacía")
    void listar_practica_sin_mensajes_devuelve_lista_vacia() {
        List<MensajeResponse> mensajes = mensajeService.listarPorPractica(practica.getId());

        assertThat(mensajes).isEmpty();
    }

    @Test
    @DisplayName("Listar mensajes devuelve todos en orden cronológico ascendente")
    void listar_mensajes_orden_cronologico() {
        mensajeService.guardar(new MensajeRequest("Primer mensaje"), alumno.getEmail(), practica.getId());
        mensajeService.guardar(new MensajeRequest("Segundo mensaje"), tutorCentro.getEmail(), practica.getId());

        List<MensajeResponse> mensajes = mensajeService.listarPorPractica(practica.getId());

        assertThat(mensajes).hasSize(2);
        assertThat(mensajes.get(0).contenido()).isEqualTo("Primer mensaje");
        assertThat(mensajes.get(1).contenido()).isEqualTo("Segundo mensaje");
    }

    @Test
    @DisplayName("La respuesta incluye nombre, apellidos y fechaEnvio del remitente")
    void respuesta_incluye_datos_del_remitente() {
        MensajeResponse resp = mensajeService.guardar(
                new MensajeRequest("Comprobar datos"), alumno.getEmail(), practica.getId());

        assertThat(resp.remitenteNombre()).isEqualTo("Alumno");
        assertThat(resp.remitenteApellidos()).isEqualTo("Chat");
        assertThat(resp.fechaEnvio()).isNotNull();
    }

    @Test
    @DisplayName("Varios participantes pueden enviar mensajes y todos aparecen en el historial")
    void varios_participantes_pueden_chatear() {
        mensajeService.guardar(new MensajeRequest("Hola soy el alumno"), alumno.getEmail(), practica.getId());
        mensajeService.guardar(new MensajeRequest("Hola soy el tutor"), tutorCentro.getEmail(), practica.getId());
        mensajeService.guardar(new MensajeRequest("Hola soy la empresa"), tutorEmpresa.getEmail(), practica.getId());

        List<MensajeResponse> mensajes = mensajeService.listarPorPractica(practica.getId());

        assertThat(mensajes).hasSize(3);
        assertThat(mensajes).extracting(MensajeResponse::remitenteId)
                .containsExactlyInAnyOrder(alumno.getId(), tutorCentro.getId(), tutorEmpresa.getId());
    }
}
