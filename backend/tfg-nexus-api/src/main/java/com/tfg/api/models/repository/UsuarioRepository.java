package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para la gestión de persistencia de la entidad Usuario.
 */
@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    /**
     * Busca un usuario por su dirección de email para el login.
     */
    Optional<Usuario> findByEmail(String email);

    /**
     * Comprueba si ya existe un usuario con el DNI indicado.
     */
    Boolean existsByDni(String dni);

    /**
     * Comprueba si ya existe un usuario con el email indicado.
     */
    Boolean existsByEmail(String email);
}
