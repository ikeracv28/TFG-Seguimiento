package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "ausencias")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ausencia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "practica_id", nullable = false)
    private Practica practica;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String motivo;

    /** PENDIENTE → JUSTIFICADA | INJUSTIFICADA */
    @Column(length = 20)
    @Builder.Default
    private String tipo = "PENDIENTE";

    // @Lob mapea a oid en Hibernate 6 / PostgreSQL — usar columnDefinition="bytea" para bytea real
    @Column(name = "justificante", columnDefinition = "bytea")
    private byte[] justificante;

    @Column(name = "nombre_fichero", length = 255)
    private String nombreFichero;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registrada_por_id", nullable = false)
    private Usuario registradaPor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "revisada_por_id")
    private Usuario revisadaPor;

    @Column(name = "comentario_revision", columnDefinition = "TEXT")
    private String comentarioRevision;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
