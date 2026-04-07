package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad que representa la tabla de centros educativos en la BBDD.
 */
@Entity
@Table(name = "centros")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Centro {

    /**
     * Identificador único autoincremental.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre del centro educativo.
     */
    @Column(nullable = false, length = 100)
    private String nombre;

    /**
     * Dirección física del centro.
     */
    @Column(columnDefinition = "TEXT")
    private String direccion;

    /**
     * Teléfono de contacto.
     */
    @Column(length = 20)
    private String telefono;

    /**
     * Correo electrónico institucional.
     */
    @Column(length = 100)
    private String email;

    /**
     * Fecha de registro en el sistema.
     */
    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
