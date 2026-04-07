package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Entidad que representa la tabla de roles de usuario en la BBDD.
 */
@Entity
@Table(name = "roles")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Rol {

    /**
     * Identificador único autoincremental del rol.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /**
     * Nombre identificativo del rol (Ej: ROLE_ALUMNO).
     */
    @Column(unique = true, nullable = false, length = 50)
    private String nombre;

    /**
     * Descripción de las funciones asociadas al rol.
     */
    @Column(columnDefinition = "TEXT")
    private String descripcion;
}
