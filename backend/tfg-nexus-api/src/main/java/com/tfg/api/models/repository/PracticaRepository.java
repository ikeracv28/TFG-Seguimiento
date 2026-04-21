package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Practica;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio para la entidad Practica.
 * Proporciona acceso a los datos de los convenios de formación.
 */
@Repository
public interface PracticaRepository extends JpaRepository<Practica, Long> {

    /**
     * Busca una práctica por su código único de expediente.
     */
    Optional<Practica> findByCodigo(String codigo);

    /**
     * Obtiene todas las prácticas asociadas a un alumno específico.
     */
    List<Practica> findByAlumnoId(Long alumnoId);

    /**
     * Obtiene las prácticas donde el usuario es el tutor del centro.
     */
    List<Practica> findByTutorCentroId(Long tutorId);

    /**
     * Obtiene las prácticas donde el usuario es el tutor de la empresa.
     */
    List<Practica> findByTutorEmpresaId(Long tutorId);

    /**
     * Obtiene las prácticas vinculadas a una empresa específica.
     */
    List<Practica> findByEmpresaId(Long empresaId);

    /**
     * Verifica si ya existe una práctica con un código determinado.
     */
    boolean existsByCodigo(String codigo);

    /**
     * Busca la práctica activa de un alumno.
     * Devuelve Optional para manejar el caso de que no tenga práctica activa.
     */
    Optional<Practica> findFirstByAlumnoIdAndEstado(Long alumnoId, String estado);
}
