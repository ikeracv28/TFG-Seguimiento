package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entidad que representa el diario o parte semanal de seguimiento de un alumno.
 */
@Entity
@Table(name = "seguimientos")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Seguimiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * La práctica a la que pertenece este seguimiento.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false)
    private Practica practica;

    /**
     * Fecha a la que corresponde el registro de actividades.
     */
    @Column(name = "fecha_registro", nullable = false)
    private LocalDate fechaRegistro;

    /**
     * Cantidad de horas realizadas en esa fecha específica.
     */
    @Column(name = "horas_realizadas", nullable = false)
    private Integer horasRealizadas;

    /**
     * Descripción detallada de las tareas llevadas a cabo.
     */
    @Column(columnDefinition = "TEXT")
    private String descripcion;

    /**
     * Estado del seguimiento: PENDIENTE, VALIDADO, RECHAZADO.
     */
    @Column(length = 20)
    @Builder.Default
    private String estado = "PENDIENTE";

    /**
     * Usuario (Tutor) que valida este registro específico.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "validado_por")
    private Usuario validadoPor;

    /**
     * Feedback opcional del tutor tras la validación o rechazo.
     */
    @Column(name = "comentario_tutor", columnDefinition = "TEXT")
    private String comentarioTutor;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
