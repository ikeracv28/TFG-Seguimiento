package com.tfg.api.services;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.models.dto.AusenciaRequest;
import com.tfg.api.models.dto.AusenciaResponse;
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
import org.springframework.mock.web.MockMultipartFile;
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
class AusenciaServiceTest {

    @Autowired private AusenciaService ausenciaService;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private EmpresaRepository empresaRepository;

    private Practica practica;
    private Usuario alumno;
    private Usuario tutorEmpresa;

    private void setSecurityContext(String email) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, List.of()));
    }

    @BeforeEach
    void setUp() {
        alumno = usuarioRepository.save(Usuario.builder()
                .dni("AU000001A").nombre("Alumno").apellidos("Ausencia")
                .email("alumno.ausencia@test.com").passwordHash("hash").activo(true).build());
        Usuario tutorC = usuarioRepository.save(Usuario.builder()
                .dni("AU000002B").nombre("Tutor").apellidos("Centro")
                .email("tutor.centro.aus@test.com").passwordHash("hash").activo(true).build());
        tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("AU000003C").nombre("Tutor").apellidos("Empresa")
                .email("tutor.empresa.aus@test.com").passwordHash("hash").activo(true).build());
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("EmpresaAus").cif("B99900001").build());
        practica = practicaRepository.save(Practica.builder()
                .codigo("AUS-001").alumno(alumno).tutorCentro(tutorC)
                .tutorEmpresa(tutorEmpresa).empresa(empresa).estado("ACTIVA").build());
    }

    @Test
    @DisplayName("Alumno puede registrar una ausencia en su practica activa")
    void alumno_puede_registrar_ausencia() {
        AusenciaRequest req = new AusenciaRequest(practica.getId(), LocalDate.now(), "Motivo de prueba largo");
        AusenciaResponse resp = ausenciaService.registrar(req, alumno.getEmail());

        assertThat(resp.id()).isNotNull();
        assertThat(resp.tipo()).isEqualTo("PENDIENTE");
        assertThat(resp.practicaId()).isEqualTo(practica.getId());
    }

    @Test
    @DisplayName("No se permite duplicar ausencia en la misma fecha")
    void no_permite_duplicado_por_fecha() {
        LocalDate hoy = LocalDate.now();
        ausenciaService.registrar(new AusenciaRequest(practica.getId(), hoy, "Primera ausencia"), alumno.getEmail());

        assertThatThrownBy(() ->
            ausenciaService.registrar(new AusenciaRequest(practica.getId(), hoy, "Duplicado"), alumno.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("Ya existe");
    }

    @Test
    @DisplayName("Otro alumno no puede registrar ausencias en una practica ajena")
    void otro_alumno_no_puede_registrar_en_practica_ajena() {
        Usuario otroAlumno = usuarioRepository.save(Usuario.builder()
                .dni("AU000004D").nombre("Otro").apellidos("Alumno")
                .email("otro.alumno@test.com").passwordHash("hash").activo(true).build());

        assertThatThrownBy(() ->
            ausenciaService.registrar(
                    new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(1), "Intento ilegal"),
                    otroAlumno.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("acceso");
    }

    @Test
    @DisplayName("Tutor de empresa puede revisar una ausencia como JUSTIFICADA")
    void tutor_empresa_puede_revisar_justificada() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(2), "Enfermedad documentada"),
                alumno.getEmail());

        AusenciaResponse revisada = ausenciaService.revisar(
                creada.id(), "JUSTIFICADA", "Aportó baja médica", tutorEmpresa.getEmail());

        assertThat(revisada.tipo()).isEqualTo("JUSTIFICADA");
    }

    @Test
    @DisplayName("Tutor de empresa puede revisar una ausencia como INJUSTIFICADA")
    void tutor_empresa_puede_revisar_injustificada() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(3), "Sin justificacion aportada"),
                alumno.getEmail());

        AusenciaResponse revisada = ausenciaService.revisar(
                creada.id(), "INJUSTIFICADA", "No presentó documentos", tutorEmpresa.getEmail());

        assertThat(revisada.tipo()).isEqualTo("INJUSTIFICADA");
    }

    @Test
    @DisplayName("No se puede revisar una ausencia ya revisada")
    void no_se_puede_revisar_dos_veces() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(4), "Motivo revisable test"),
                alumno.getEmail());
        ausenciaService.revisar(creada.id(), "JUSTIFICADA", "OK", tutorEmpresa.getEmail());

        assertThatThrownBy(() ->
            ausenciaService.revisar(creada.id(), "INJUSTIFICADA", "Cambio ilegal", tutorEmpresa.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("ya fue revisada");
    }

    @Test
    @DisplayName("Tipo de revision invalido lanza excepcion")
    void tipo_revision_invalido_lanza_excepcion() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(5), "Prueba tipo invalido"),
                alumno.getEmail());

        assertThatThrownBy(() ->
            ausenciaService.revisar(creada.id(), "INVALIDO", null, tutorEmpresa.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("no válido");
    }

    @Test
    @DisplayName("Alumno puede adjuntar justificante a ausencia PENDIENTE")
    void alumno_puede_adjuntar_justificante() throws Exception {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(6), "Justificante adjuntado"),
                alumno.getEmail());

        MockMultipartFile pdf = new MockMultipartFile(
                "fichero", "baja.pdf", "application/pdf", "contenido-pdf".getBytes());

        AusenciaResponse conJustificante = ausenciaService.adjuntarJustificante(
                creada.id(), pdf, alumno.getEmail());

        assertThat(conJustificante.nombreFichero()).isEqualTo("baja.pdf");
    }

    @Test
    @DisplayName("No se puede adjuntar fichero con tipo MIME no permitido")
    void no_permite_mime_invalido() throws Exception {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(7), "Intentar mime raro"),
                alumno.getEmail());

        MockMultipartFile exe = new MockMultipartFile(
                "fichero", "virus.exe", "application/x-msdownload", "contenido".getBytes());

        assertThatThrownBy(() ->
            ausenciaService.adjuntarJustificante(creada.id(), exe, alumno.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("PDF");
    }

    @Test
    @DisplayName("Listar ausencias de una practica devuelve la lista correcta")
    void listar_ausencias_por_practica() {
        ausenciaService.registrar(new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(1), "Primera ausencia test"), alumno.getEmail());
        ausenciaService.registrar(new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(2), "Segunda ausencia test"), alumno.getEmail());

        setSecurityContext(alumno.getEmail());
        List<AusenciaResponse> lista = ausenciaService.listarPorPractica(practica.getId());

        assertThat(lista).hasSize(2);
    }

    @Test
    @DisplayName("Alumno puede eliminar una ausencia PENDIENTE")
    void alumno_puede_eliminar_ausencia_pendiente() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(8), "Para eliminar despues"),
                alumno.getEmail());

        setSecurityContext(alumno.getEmail());
        ausenciaService.eliminar(creada.id(), alumno.getEmail());

        assertThat(ausenciaService.listarPorPractica(practica.getId())).isEmpty();
    }

    @Test
    @DisplayName("No se puede eliminar una ausencia ya revisada")
    void no_puede_eliminar_ausencia_revisada() {
        AusenciaResponse creada = ausenciaService.registrar(
                new AusenciaRequest(practica.getId(), LocalDate.now().minusDays(9), "Revisada no eliminable"),
                alumno.getEmail());
        ausenciaService.revisar(creada.id(), "JUSTIFICADA", "OK", tutorEmpresa.getEmail());

        assertThatThrownBy(() ->
            ausenciaService.eliminar(creada.id(), alumno.getEmail())
        ).isInstanceOf(BusinessRuleException.class)
         .hasMessageContaining("revisada");
    }
}
