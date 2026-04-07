package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.AuthResponse;
import com.tfg.api.models.dto.RegisterRequest;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.models.entity.Rol;
import com.tfg.api.models.entity.Usuario;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

import java.util.Set;
import java.util.stream.Collectors;

/**
 * Interface para el mapeo entre la entidad Usuario y sus diferentes DTOs.
 */
@Mapper(componentModel = "spring")
public interface UsuarioMapper {

    /**
     * Mapea el DTO de registro a la entidad Usuario para persistencia.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "passwordHash", source = "password") // Mapeamos password de DTO a passwordHash de Entity
    @Mapping(target = "centro", ignore = true) // El centro se asignará en el Service
    @Mapping(target = "roles", ignore = true)  // Los roles se asignarán en el Service
    @Mapping(target = "activo", constant = "true")
    @Mapping(target = "fechaCreacion", ignore = true)
    Usuario registerToEntity(RegisterRequest request);

    /**
     * Mapea el usuario autenticado y su token al DTO de respuesta de autenticación.
     */
    @Mapping(target = "token", source = "token")
    @Mapping(target = "nombre", expression = "java(usuario.getNombre() + \" \" + usuario.getApellidos())")
    @Mapping(target = "roles", source = "usuario.roles", qualifiedByName = "mapRoles")
    AuthResponse toAuthResponse(Usuario usuario, String token);

    /**
     * Mapea la entidad Usuario al DTO de respuesta de perfil.
     */
    @Mapping(target = "centroNombre", source = "usuario.centro.nombre")
    @Mapping(target = "roles", source = "usuario.roles", qualifiedByName = "mapRoles")
    UsuarioResponse toResponse(Usuario usuario);

    /**
     * Convierte el Set de objetos Rol en un Set de Strings con sus nombres.
     */
    @Named("mapRoles")
    default Set<String> mapRoles(Set<Rol> roles) {
        if (roles == null) return Set.of();
        return roles.stream()
                .map(Rol::getNombre)
                .collect(Collectors.toSet());
    }
}
