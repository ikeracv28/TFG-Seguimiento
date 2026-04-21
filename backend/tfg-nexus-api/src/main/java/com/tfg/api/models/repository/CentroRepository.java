package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Centro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio para la entidad Centro.
 * Proporciona métodos CRUD básicos para la gestión de institutos.
 */
@Repository
public interface CentroRepository extends JpaRepository<Centro, Long> {
    // Aquí podríamos añadir métodos personalizados si fuera necesario, 
    // como buscar centros por nombre o por código.
}
