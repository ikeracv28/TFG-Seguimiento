package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "evaluacion_final")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvaluacionFinal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false, unique = true)
    private Practica practica;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_empresa_id", nullable = false)
    private Usuario tutorEmpresa;

    // Criterios opcionales (1–10)
    @Column(name = "actitud_puntualidad", precision = 3, scale = 1)
    private BigDecimal actitudPuntualidad;

    @Column(name = "competencia_tecnica", precision = 3, scale = 1)
    private BigDecimal competenciaTecnica;

    @Column(name = "iniciativa_autonomia", precision = 3, scale = 1)
    private BigDecimal iniciativaAutonomia;

    @Column(name = "trabajo_equipo", precision = 3, scale = 1)
    private BigDecimal trabajoEquipo;

    @Column(name = "cumplimiento_tareas", precision = 3, scale = 1)
    private BigDecimal cumplimientoTareas;

    // Nota global obligatoria (0–10)
    @Column(name = "nota_global", nullable = false, precision = 4, scale = 2)
    private BigDecimal notaGlobal;

    @Column(columnDefinition = "TEXT")
    private String comentario;

    @Column(name = "fecha_evaluacion", updatable = false)
    private LocalDateTime fechaEvaluacion;

    @PrePersist
    protected void onCreate() {
        this.fechaEvaluacion = LocalDateTime.now();
    }
}
