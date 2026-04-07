package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entidad que representa la tabla de prácticas (FCT) en la BBDD.
 */
@Entity
@Table(name = "practicas")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Practica {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Código identificativo único de la práctica.
     */
    @Column(unique = true, nullable = false, length = 50)
    private String codigo;

    /**
     * Relación con el alumno asignado a la práctica.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumno_id", nullable = false)
    private Usuario alumno;

    /**
     * Relación con el tutor del centro educativo.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_centro_id", nullable = false)
    private Usuario tutorCentro;

    /**
     * Relación con el tutor responsable en la empresa.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_empresa_id", nullable = false)
    private Usuario tutorEmpresa;

    /**
     * Relación con la empresa donde se realizan las prácticas.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "empresa_id", nullable = false)
    private Empresa empresa;

    @Column(name = "fecha_inicio")
    private LocalDate fechaInicio;

    @Column(name = "fecha_fin")
    private LocalDate fechaFin;

    @Column(name = "horas_totales")
    private Integer horasTotales;

    /**
     * Estado actual del flujo de la práctica.
     */
    @Column(length = 20)
    @Builder.Default
    private String estado = "BORRADOR";

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
