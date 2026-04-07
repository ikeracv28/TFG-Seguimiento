package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Empresa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para la gestión de persistencia de la entidad Empresa.
 */
@Repository
public interface EmpresaRepository extends JpaRepository<Empresa, Long> {

    /**
     * Busca una empresa por su código CIF.
     */
    Optional<Empresa> findByCif(String cif);

    /**
     * Comprueba la existencia de una empresa por su CIF.
     */
    boolean existsByCif(String cif);
}

