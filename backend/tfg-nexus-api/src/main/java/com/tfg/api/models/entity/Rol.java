package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Entidad que representa los roles de usuario en el sistema Nexus TFG.
 * Define los niveles de acceso (ALUMNO, TUTOR_CENTRO, TUTOR_EMPRESA, ADMIN).
 * 
 * Uso de Lombok:
 * @Data: Genera getters, setters, equals, hashCode y toString automáticamente.
 * @NoArgsConstructor: Constructor vacío requerido por JPA.
 * @AllArgsConstructor: Constructor con todos los campos para facilitar pruebas.
 * @Builder: Patrón de diseño para construir objetos de forma legible.
 */
@Entity
@Table(name = "roles")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Rol {

    /**
     * Identificador único del rol.
     * GenerationType.IDENTITY: Delega en la base de datos (PostgreSQL SERIAL) el autoincremento.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /**
     * Nombre del rol (ej: "ROLE_ALUMNO"). 
     * Unique = true: Evita duplicidad de roles a nivel de base de datos.
     * Not null: El rol debe tener un nombre obligatoriamente.
     */
    @Column(unique = true, nullable = false, length = 50)
    private String nombre;

    /**
     * Descripción opcional sobre las funciones del rol.
     */
    @Column(columnDefinition = "TEXT")
    private String descripcion;
}
