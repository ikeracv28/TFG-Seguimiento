package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entidad central: Representa el convenio de prácticas académicas (FCT).
 * Relaciona al alumno con sus tutores y la empresa asignada.
 */
@Entity
@Table(name = "practicas")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Practica {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Código único asignado a la práctica para identificación rápida.
     */
    @Column(unique = true, nullable = false, length = 50)
    private String codigo;

    /**
     * El alumno asignado a esta práctica.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumno_id", nullable = false)
    private Usuario alumno;

    /**
     * Tutor académico responsable del seguimiento por parte del centro educativo.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_centro_id", nullable = false)
    private Usuario tutorCentro;

    /**
     * Tutor profesional responsable del alumno dentro de la empresa.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_empresa_id", nullable = false)
    private Usuario tutorEmpresa;

    /**
     * La empresa donde se desarrolla la formación.
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
     * Estado actual de la práctica: BORRADOR, ACTIVA, FINALIZADA.
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
