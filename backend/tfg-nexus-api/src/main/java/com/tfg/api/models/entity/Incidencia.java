package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad que representa una incidencia ocurrida durante el periodo de prácticas.
 * Permite documentar ausencias, conflictos o problemas técnicos.
 */
@Entity
@Table(name = "incidencias")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Incidencia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Relación con la práctica en la que ocurre la incidencia.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false)
    private Practica practica;

    /**
     * Usuario que reporta la incidencia (Alumno, Tutor Centro o Tutor Empresa).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creada_por", nullable = false)
    private Usuario creadaPor;

    /**
     * Tipo de incidencia: AUSENCIA, COMPORTAMIENTO, ACCIDENTE, OTROS.
     */
    @Column(length = 50)
    private String tipo;

    /**
     * Descripción detallada de lo sucedido.
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    /**
     * Estado de la resolución: ABIERTA, EN_PROCESO, RESUELTA, CERRADA.
     */
    @Column(length = 20)
    @Builder.Default
    private String estado = "ABIERTA";

    /**
     * Usuario (normalmente tutor o admin) que gestiona o resuelve la incidencia.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resuelta_por")
    private Usuario resueltaPor;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_resolucion")
    private LocalDateTime fechaResolucion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
