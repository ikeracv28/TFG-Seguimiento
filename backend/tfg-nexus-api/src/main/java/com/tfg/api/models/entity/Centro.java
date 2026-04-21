package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad que representa un centro educativo (instituto) en el ecosistema Nexus TFG.
 * Es el nodo que agrupa a alumnos y tutores académicos.
 */
@Entity
@Table(name = "centros")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Centro {

    /**
     * Identificador único (BIGINT en PostgreSQL).
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre descriptivo del instituto.
     */
    @Column(nullable = false, length = 100)
    private String nombre;

    /**
     * Ubicación física del centro.
     */
    @Column(columnDefinition = "TEXT")
    private String direccion;

    /**
     * Teléfono de contacto.
     */
    @Column(length = 20)
    private String telefono;

    /**
     * Correo institucional.
     */
    @Column(length = 100)
    private String email;

    /**
     * Marca de tiempo de cuándo se registró el centro.
     * @PrePersist: Ejecuta este método justo antes de que se guarde en la BD.
     */
    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
