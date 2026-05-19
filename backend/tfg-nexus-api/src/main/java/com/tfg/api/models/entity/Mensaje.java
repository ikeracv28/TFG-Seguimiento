package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mensajes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Mensaje {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false)
    private Practica practica;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "remitente_id", nullable = false)
    private Usuario remitente;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String contenido;

    @Column(nullable = false, length = 20)
    private String canal = "ALUMNO";

    @Column(nullable = false, length = 20)
    private String tipo = "TEXTO";

    @Column(name = "adjunto_nombre")
    private String adjuntoNombre;

    @Column(name = "adjunto_datos", columnDefinition = "bytea")
    private byte[] adjuntoDatos;

    @Column(name = "adjunto_tipo", length = 100)
    private String adjuntoTipo;

    @Column(name = "fecha_envio", nullable = false)
    private LocalDateTime fechaEnvio;

    @PrePersist
    protected void onCreate() {
        if (this.fechaEnvio == null) this.fechaEnvio = LocalDateTime.now();
    }
}
