package com.tfg.api.security;

import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Rol;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.RolRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Set;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * [OWASP A01 — Broken Access Control]
 *
 * A01.2: Verifica que un alumno NO puede acceder a la práctica de otro alumno (IDOR).
 * A01.3: Verifica que un alumno sin práctica asignada NO puede acceder a prácticas ajenas.
 *
 * Sin @Transactional en la clase: MockMvc lanza peticiones HTTP reales en transacciones
 * independientes, por lo que los datos del @BeforeEach deben estar COMPROMETIDOS en BD
 * antes de que el request llegue al filtro de seguridad.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class A01AccessControlTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtUtils jwtUtils;
    @Autowired private UsuarioRepository usuarioRepository;
    @Autowired private RolRepository rolRepository;
    @Autowired private EmpresaRepository empresaRepository;
    @Autowired private PracticaRepository practicaRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    private Long practicaDeAId;
    private String tokenAlumnoA;
    private String tokenAlumnoB;
    private String tokenAlumnoSinPractica;

    // Guardamos referencias para limpiar en @AfterEach
    private Long alumnoAId;
    private Long alumnoBId;
    private Long alumnoSinPracticaId;
    private Long tutorCentroId;
    private Long tutorEmpresaId;
    private Long empresaId;

    @BeforeEach
    void setUp() {
        Rol rolAlumno = rolRepository.findByNombre("ROLE_ALUMNO")
                .orElseGet(() -> rolRepository.save(
                        Rol.builder().nombre("ROLE_ALUMNO").descripcion("Alumno FCT").build()));

        Rol rolTutorC = rolRepository.findByNombre("ROLE_TUTOR_CENTRO")
                .orElseGet(() -> rolRepository.save(
                        Rol.builder().nombre("ROLE_TUTOR_CENTRO").descripcion("Tutor Centro").build()));

        Rol rolTutorE = rolRepository.findByNombre("ROLE_TUTOR_EMPRESA")
                .orElseGet(() -> rolRepository.save(
                        Rol.builder().nombre("ROLE_TUTOR_EMPRESA").descripcion("Tutor Empresa").build()));

        Usuario alumnoA = usuarioRepository.save(Usuario.builder()
                .dni("A01001A").nombre("AlumnoA").apellidos("Test")
                .email("alumnoA@a01test.com")
                .passwordHash(passwordEncoder.encode("Test@A01Pass1"))
                .activo(true).roles(Set.of(rolAlumno)).build());
        alumnoAId = alumnoA.getId();

        Usuario tutorCentro = usuarioRepository.save(Usuario.builder()
                .dni("A01003C").nombre("TutorC").apellidos("Test")
                .email("tutorc@a01test.com")
                .passwordHash("hash").activo(true).roles(Set.of(rolTutorC)).build());
        tutorCentroId = tutorCentro.getId();

        Usuario tutorEmpresa = usuarioRepository.save(Usuario.builder()
                .dni("A01004D").nombre("TutorE").apellidos("Test")
                .email("tutore@a01test.com")
                .passwordHash("hash").activo(true).roles(Set.of(rolTutorE)).build());
        tutorEmpresaId = tutorEmpresa.getId();

        Empresa empresa = empresaRepository.save(
                Empresa.builder().nombre("Empresa A01").cif("BA0112345").build());
        empresaId = empresa.getId();

        Practica practicaDeA = practicaRepository.save(Practica.builder()
                .codigo("A01-TEST-001")
                .alumno(alumnoA).tutorCentro(tutorCentro)
                .tutorEmpresa(tutorEmpresa).empresa(empresa)
                .estado("ACTIVA").build());
        practicaDeAId = practicaDeA.getId();

        Usuario alumnoB = usuarioRepository.save(Usuario.builder()
                .dni("A01002B").nombre("AlumnoB").apellidos("Test")
                .email("alumnoB@a01test.com")
                .passwordHash(passwordEncoder.encode("Test@A01Pass2"))
                .activo(true).roles(Set.of(rolAlumno)).build());
        alumnoBId = alumnoB.getId();

        Usuario alumnoSinPractica = usuarioRepository.save(Usuario.builder()
                .dni("A01005E").nombre("AlumnoC").apellidos("Test")
                .email("alumnoC@a01test.com")
                .passwordHash(passwordEncoder.encode("Test@A01Pass3"))
                .activo(true).roles(Set.of(rolAlumno)).build());
        alumnoSinPracticaId = alumnoSinPractica.getId();

        tokenAlumnoA           = token(alumnoA, "ROLE_ALUMNO");
        tokenAlumnoB           = token(alumnoB, "ROLE_ALUMNO");
        tokenAlumnoSinPractica = token(alumnoSinPractica, "ROLE_ALUMNO");
    }

    @AfterEach
    void tearDown() {
        // Orden inverso a la creación para respetar FKs
        if (practicaDeAId != null)     practicaRepository.deleteById(practicaDeAId);
        if (empresaId != null)         empresaRepository.deleteById(empresaId);
        if (alumnoAId != null)         usuarioRepository.deleteById(alumnoAId);
        if (alumnoBId != null)         usuarioRepository.deleteById(alumnoBId);
        if (alumnoSinPracticaId != null) usuarioRepository.deleteById(alumnoSinPracticaId);
        if (tutorCentroId != null)     usuarioRepository.deleteById(tutorCentroId);
        if (tutorEmpresaId != null)    usuarioRepository.deleteById(tutorEmpresaId);
        // Los roles no se borran — son datos de referencia compartidos
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private String token(Usuario usuario, String rolNombre) {
        UserDetails ud = new User(
                usuario.getEmail(),
                usuario.getPasswordHash(),
                List.of(new SimpleGrantedAuthority(rolNombre)));
        return jwtUtils.generateToken(ud);
    }

    // ── A01.2 — IDOR entre alumnos ─────────────────────────────────────────────

    @Test
    @DisplayName("[A01.2] Alumno A puede consultar su propia práctica — acceso legítimo")
    void alumnoA_puede_ver_su_propia_practica() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/{id}", practicaDeAId)
                        .header("Authorization", "Bearer " + tokenAlumnoA))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("[A01.2] Alumno B NO puede ver la práctica de Alumno A — IDOR bloqueado (403)")
    void alumnoB_no_puede_acceder_a_practica_de_alumnoA() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/{id}", practicaDeAId)
                        .header("Authorization", "Bearer " + tokenAlumnoB))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("[A01.2] Alumno B NO puede listar las prácticas de Alumno A por alumnoId — IDOR bloqueado (403)")
    void alumnoB_no_puede_listar_practicas_de_alumnoA_por_id() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/alumno/{alumnoId}", alumnoAId)
                        .header("Authorization", "Bearer " + tokenAlumnoB))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("[A01.2] Alumno B NO puede acceder al listado global de prácticas — solo tutores y admin (403)")
    void alumnoB_no_puede_listar_todas_las_practicas() throws Exception {
        mockMvc.perform(get("/api/v1/practicas")
                        .header("Authorization", "Bearer " + tokenAlumnoB))
                .andExpect(status().isForbidden());
    }

    // ── A01.3 — Alumno sin práctica asignada ───────────────────────────────────

    @Test
    @DisplayName("[A01.3] Alumno sin práctica NO puede acceder a una práctica ajena — IDOR bloqueado (403)")
    void alumnoSinPractica_no_puede_ver_practica_ajena() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/{id}", practicaDeAId)
                        .header("Authorization", "Bearer " + tokenAlumnoSinPractica))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("[A01.3] Alumno sin práctica NO puede listar prácticas de otro alumno por alumnoId (403)")
    void alumnoSinPractica_no_puede_listar_practicas_de_otro_alumno() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/alumno/{alumnoId}", alumnoAId)
                        .header("Authorization", "Bearer " + tokenAlumnoSinPractica))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("[A01.3] Alumno sin práctica recibe 403 — no hay fuga de datos aunque la práctica exista")
    void alumnoSinPractica_recibe_403_no_404_sin_fuga_de_informacion() throws Exception {
        // 403 y no 404: el sistema confirma que no tiene acceso, no que la práctica no exista.
        // Devolver 404 revelaría qué IDs existen o no (enumeración de recursos).
        mockMvc.perform(get("/api/v1/practicas/{id}", practicaDeAId)
                        .header("Authorization", "Bearer " + tokenAlumnoSinPractica))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("[A01.3] Petición sin token recibe 403 — no hay acceso anónimo a recursos protegidos")
    void peticion_sin_token_es_rechazada() throws Exception {
        mockMvc.perform(get("/api/v1/practicas/{id}", practicaDeAId))
                .andExpect(status().isForbidden());
    }
}
