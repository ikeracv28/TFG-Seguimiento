package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Centro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio para la gestión de persistencia de la entidad Centro.
 */
@Repository
public interface CentroRepository extends JpaRepository<Centro, Long> {
}
