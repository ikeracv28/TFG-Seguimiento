package com.tfg.api.models.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * Entidad central del sistema: El Usuario.
 * Gestiona tanto a Alumnos, Tutores (Centro/Empresa) y Administradores.
 */
@Entity
@Table(name = "usuarios")
@Getter
@Setter
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * DNI/NIE: Obligatorio y único para identificación formal en España.
     */
    @Column(unique = true, nullable = false, length = 20)
    private String dni;

    @Column(nullable = false, length = 50)
    private String nombre;

    @Column(nullable = false, length = 100)
    private String apellidos;

    /**
     * Email: Único. Se usará habitualmente como 'username' para el Login con JWT.
     */
    @Column(unique = true, nullable = false, length = 100)
    private String email;

    /**
     * Almacenamiento del Hash de la contraseña.
     * Nunca debemos almacenar contraseñas en texto plano.
     */
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    /**
     * Relación con el centro educativo.
     * @ManyToOne: Varios usuarios pueden pertenecer a un mismo centro.
     * @JoinColumn: Especifica la clave foránea en la tabla usuarios.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "centro_id")
    private Centro centro;

    /**
     * Estado de la cuenta: Permite deshabilitar el acceso sin borrar los datos.
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean activo = true;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    /**
     * Relación Many-to-Many con Roles.
     * Un usuario puede tener varios roles (ej: Tutor de Centro y Administrador).
     * 
     * @JoinTable: Define la tabla intermedia 'usuario_roles' de forma declarativa.
     * fetch = FetchType.EAGER: Al loguear al usuario, necesitamos sus roles al instante 
     * para la seguridad.
     */
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "usuario_roles",
        joinColumns = @JoinColumn(name = "usuario_id"),
        inverseJoinColumns = @JoinColumn(name = "rol_id")
    )
    @Builder.Default
    private Set<Rol> roles = new HashSet<>();

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
