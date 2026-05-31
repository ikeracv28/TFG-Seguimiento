package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "tutorias")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Tutoria {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tutor_centro_id", nullable = false)
    private Usuario tutorCentro;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumno_id", nullable = false)
    private Usuario alumno;

    @Column(nullable = false)
    private LocalDateTime fechaHora;

    @Column(nullable = false)
    private Integer duracionMinutos;

    @Column(nullable = false)
    @Builder.Default
    private Boolean notificado = false;

    @Column(nullable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        if (fechaCreacion == null) fechaCreacion = LocalDateTime.now();
        if (duracionMinutos == null) duracionMinutos = 15;
    }
}
