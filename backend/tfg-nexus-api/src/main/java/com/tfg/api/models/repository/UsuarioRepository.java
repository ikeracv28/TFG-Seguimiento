package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

/**
 * Repositorio para la entidad Usuario.
 * Gestiona el acceso a la tabla de usuarios en PostgreSQL.
 * 
 * JpaRepository: Proporciona métodos CRUD para el manejo de la entidad.
 * Spring Boot genera automáticamente las consultas SQL por nosotros en tiempo de ejecución.
 */
@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    /**
     * Método fundamental para el proceso de Login (Autenticación).
     * 
     * Spring Data JPA utiliza "Query Derivation": al llamar al método 
     * 'findByEmail', el framework analiza el nombre del método y genera 
     * automáticamente la consulta: 
     * "SELECT * FROM usuarios WHERE email = ?"
     * 
     * @param email El correo electrónico del usuario a buscar.
     * @return Un Optional que contendrá al Usuario si el email es correcto.
     */
    Optional<Usuario> findByEmail(String email);

    /**
     * Verifica si ya existe un usuario con un DNI determinado. 
     * Útil para validaciones antes de crear un nuevo usuario.
     * 
     * @param dni El DNI a comprobar.
     * @return true si ya existe en la base de datos, false en caso contrario.
     */
    Boolean existsByDni(String dni);

    /**
     * Verifica si ya existe un usuario con un Email determinado.
     * 
     * @param email El email a comprobar.
     * @return true si ya existe, false si está libre.
     */
    Boolean existsByEmail(String email);

    List<Usuario> findAllByOrderByFechaCreacionDesc();
}
