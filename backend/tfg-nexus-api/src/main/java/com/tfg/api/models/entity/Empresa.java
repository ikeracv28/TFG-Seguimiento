package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad que representa la empresa donde se realizan las prácticas.
 * Almacena los datos de contacto y la información corporativa básica.
 */
@Entity
@Table(name = "empresas")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Nombre comercial o razón social.
     */
    @Column(nullable = false, length = 100)
    private String nombre;

    /**
     * Código de Identificación Fiscal: Obligatorio y único.
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
