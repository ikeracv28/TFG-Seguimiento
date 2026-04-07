package com.tfg.api.models.repository;

import com.tfg.api.models.entity.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test de integración para la capa de persistencia (Repositories).
 * Verifica que las entidades se guarden correctamente y mantengan sus relaciones.
 */
@DataJpaTest
@ActiveProfiles("test")
public class ModelPersistenceTest {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private CentroRepository centroRepository;

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private PracticaRepository practicaRepository;

    @Test
    @DisplayName("Debe persistir un flujo completo de práctica (Usuario -> Empresa -> Practica)")
    void should_persist_full_practice_flow() {
        // 1. Arrange: Preparar datos básicos
        Rol rolAlumno = rolRepository.save(Rol.builder().nombre("ROLE_ALUMNO").build());
        Rol rolTutor = rolRepository.save(Rol.builder().nombre("ROLE_TUTOR_CENTRO").build());

        Centro centro = centroRepository.save(Centro.builder()
                .nombre("IES Test")
                .email("test@centro.com")
                .build());

        // Crear Alumno
        Usuario alumno = Usuario.builder()
                .dni("12345678A")
                .nombre("Juan")
                .apellidos("Alumno")
                .email("juan@test.com")
                .passwordHash("hash")
                .centro(centro)
                .activo(true)
                .build();
        alumno.getRoles().add(rolAlumno);
        usuarioRepository.save(alumno);

        // Crear Tutor
        Usuario tutor = Usuario.builder()
                .dni("87654321B")
                .nombre("Pedro")
                .apellidos("Tutor")
                .email("pedro@test.com")
                .passwordHash("hash")
                .centro(centro)
                .build();
        tutor.getRoles().add(rolTutor);
        usuarioRepository.save(tutor);

        // Crear Empresa
        Empresa empresa = empresaRepository.save(Empresa.builder()
                .nombre("Tech Solutions")
                .cif("B12345678")
                .build());

        // 2. Act: Crear la Práctica (Nexo de unión)
        Practica practica = Practica.builder()
                .codigo("PRAC-2026-001")
                .alumno(alumno)
                .tutorCentro(tutor)
                .tutorEmpresa(tutor) // Usamos el mismo para el test de persistencia
                .empresa(empresa)
                .fechaInicio(LocalDate.now())
                .fechaFin(LocalDate.now().plusMonths(3))
                .estado("ACTIVA")
                .build();
        
        Practica savedPractica = practicaRepository.save(practica);

        // 3. Assert: Verificar persistencia y relaciones
        assertNotNull(savedPractica.getId(), "La práctica debería tener un ID generado");
        assertEquals("PRAC-2026-001", savedPractica.getCodigo());
        
        // Verificar relaciones Lazy
        assertEquals(alumno.getId(), savedPractica.getAlumno().getId());
        assertEquals(empresa.getId(), savedPractica.getEmpresa().getId());
        assertEquals("ROLE_ALUMNO", savedPractica.getAlumno().getRoles().iterator().next().getNombre());
        
        // Buscar por código en el repositorio
        Optional<Practica> found = practicaRepository.findByCodigo("PRAC-2026-001");
        assertTrue(found.isPresent());
        assertEquals("Tech Solutions", found.get().getEmpresa().getNombre());
    }
}
