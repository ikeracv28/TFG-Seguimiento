package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

/**
 * Repositorio para la gestión de persistencia de la entidad Practica.
 */
@Repository
public interface PracticaRepository extends JpaRepository<Practica, Long> {

    /**
     * Busca una práctica por su código único.
     */
    Optional<Practica> findByCodigo(String codigo);

    /**
     * Lista las prácticas asociadas a un alumno específico.
     */
    List<Practica> findByAlumno(Usuario alumno);

    /**
     * Lista las prácticas supervisadas por un tutor de centro.
     */
    List<Practica> findByTutorCentro(Usuario tutorCentro);

    /**
     * Lista las prácticas de una empresa específica por su ID.
     */
    List<Practica> findByEmpresaId(Long empresaId);

    /**
     * Filtra las prácticas según su estado actual.
     */
    List<Practica> findByEstado(String estado);
}
