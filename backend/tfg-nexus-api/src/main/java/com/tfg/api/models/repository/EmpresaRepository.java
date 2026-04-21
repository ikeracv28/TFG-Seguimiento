package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Empresa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio para la entidad Empresa.
 * Ofrece métodos predefinidos por Spring Data JPA para la persistencia en PostgreSQL.
 */
@Repository
public interface EmpresaRepository extends JpaRepository<Empresa, Long> {

    /**
     * Busca una empresa por su CIF.
     * @param cif Código de identificación fiscal.
     * @return Un Optional con la empresa si existe.
     */
    Optional<Empresa> findByCif(String cif);

    /**
     * Verifica si ya existe una empresa con un CIF determinado.
     * @param cif Código de identificación fiscal.
     * @return true si existe, false en caso contrario.
     */
    boolean existsByCif(String cif);
}
