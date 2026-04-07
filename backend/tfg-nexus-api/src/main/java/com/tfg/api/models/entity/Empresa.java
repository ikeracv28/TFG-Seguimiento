package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad que representa la tabla de empresas en la BBDD.
 */
@Entity
@Table(name = "empresas")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre de la empresa colaboradora.
     */
    @Column(nullable = false, length = 100)
    private String nombre;

    /**
     * Identificador fiscal de la empresa (CIF).
     */
    @Column(unique = true, nullable = false, length = 20)
    private String cif;

    @Column(columnDefinition = "TEXT")
    private String direccion;

    @Column(name = "email_contacto", length = 100)
    private String emailContacto;

    @Column(name = "telefono_contacto", length = 20)
    private String telefonoContacto;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
