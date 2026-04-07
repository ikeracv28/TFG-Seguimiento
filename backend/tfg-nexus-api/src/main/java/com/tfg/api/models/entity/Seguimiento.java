package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entidad que representa la tabla de seguimientos diarios en la BBDD.
 */
@Entity
@Table(name = "seguimientos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Seguimiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Relación con la práctica a la que pertenece el seguimiento.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false)
    private Practica practica;

    /**
     * Fecha del registro de la actividad diaria.
     */
    @Column(name = "fecha_registro", nullable = false)
    private LocalDate fechaRegistro;

    /**
     * Número de horas realizadas en la jornada.
     */
    @Column(name = "horas_realizadas", nullable = false)
    private Integer horasRealizadas;

    /**
     * Descripción de las tareas llevadas a cabo por el alumno.
     */
    @Column(columnDefinition = "TEXT")
    private String descripcion;

    /**
     * Estado de validación del seguimiento.
     */
    @Column(length = 20)
    @Builder.Default
    private String estado = "PENDIENTE";

    /**
     * Relación con el tutor que valida el registro.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "validado_por")
    private Usuario validadoPor;

    /**
     * Comentarios de feedback proporcionados por el tutor.
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
