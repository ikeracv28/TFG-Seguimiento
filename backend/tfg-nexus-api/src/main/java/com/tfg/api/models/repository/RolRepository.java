package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para la entidad Rol.
 * 
 * JpaRepository: Interfaz de Spring Data JPA que proporciona métodos CRUD estándar
 * (save, findById, findAll, delete, etc.) sin necesidad de implementar código manual.
 * 
 * Parámetros:
 * - Rol: La entidad que gestiona este repositorio.
 * - Integer: El tipo de dato de la clave primaria (@Id) de la entidad Rol.
 */
@Repository
public interface RolRepository extends JpaRepository<Rol, Integer> {

    /**
     * Busca un rol por su nombre exacto (ej: "ROLE_ALUMNO").
     * 
     * @param nombre El nombre del rol a buscar.
     * @return Un Optional que contiene el Rol si se encuentra, o vacío en caso contrario.
     * 
     * El uso de Optional es una buena práctica en Java 8+ para evitar NullPointerException 
     * y obligar al desarrollador a manejar el caso en que el dato no exista.
     */
    Optional<Rol> findByNombre(String nombre);
}
