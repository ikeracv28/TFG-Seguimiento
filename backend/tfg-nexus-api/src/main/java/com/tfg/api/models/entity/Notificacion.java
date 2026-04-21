package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entidad para gestionar las notificaciones del sistema a los usuarios.
 * Avisa sobre validaciones de seguimientos, nuevas incidencias o mensajes.
 */
@Entity
@Table(name = "notificaciones")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Usuario destinatario de la notificación.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    /**
     * Categoría de la notificación: SEGUIMIENTO, INCIDENCIA, CHAT, SISTEMA.
     */
    @Column(length = 50)
    private String tipo;

    /**
     * Texto informativo de la notificación.
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String mensaje;

    /**
     * Indica si el usuario ya ha visualizado la notificación.
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean leida = false;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
