package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para la gestión de persistencia de la entidad Rol.
 */
@Repository
public interface RolRepository extends JpaRepository<Rol, Integer> {

    /**
     * Busca un rol por su nombre identificativo.
     */
    Optional<Rol> findByNombre(String nombre);
}
