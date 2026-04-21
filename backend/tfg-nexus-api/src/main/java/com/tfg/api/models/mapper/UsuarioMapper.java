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
 * Mapper para la conversión entre Usuario (Entidad JPA) y DTOs (Records).
 * Utiliza MapStruct para generar el código de mapeo de forma eficiente 
 * durante la compilación.
 * 
 * componentModel = "spring": Permite que Spring inyecte el Mapper 
 * como un Bean estándar (@Autowired).
 */
@Mapper(componentModel = "spring")
public interface UsuarioMapper {

    /**
     * Convierte los datos de registro en una Entidad de base de datos.
     * Ignoramos el ID (autogenerado) y la fechaCreación.
     * CRÍTICO: No mapeamos la password en claro al passwordHash directamente 
     * para evitar errores de seguridad. El hash se genera en el Service.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    @Mapping(target = "centro", ignore = true)
    @Mapping(target = "roles", ignore = true)
    @Mapping(target = "activo", constant = "true")
    @Mapping(target = "fechaCreacion", ignore = true)
    Usuario registerToEntity(RegisterRequest request);

    /**
     * Convierte un usuario de la BD en una respuesta de autenticación con el Token.
     */
    @Mapping(target = "id", source = "usuario.id")
    @Mapping(target = "token", source = "token")
    @Mapping(target = "nombre", expression = "java(usuario.getNombre() + \" \" + usuario.getApellidos())")
    @Mapping(target = "roles", source = "usuario.roles", qualifiedByName = "mapRoles")
    AuthResponse toAuthResponse(Usuario usuario, String token);

    /**
     * Convierte un usuario en un perfil público (UsuarioResponse).
     * Se utiliza una expresión para evitar NPE si el usuario no tiene centro asignado.
     */
    @Mapping(target = "centroNombre", expression = "java(usuario.getCentro() != null ? usuario.getCentro().getNombre() : \"Sin Centro\")")
    @Mapping(target = "roles", source = "usuario.roles", qualifiedByName = "mapRoles")
    UsuarioResponse toResponse(Usuario usuario);

    /**
     * Método auxiliar para extraer solo los nombres de los roles 
     * y devolver un Set<String> más ligero para el JSON.
     */
    @Named("mapRoles")
    default Set<String> mapRoles(Set<Rol> roles) {
        if (roles == null) return Set.of();
        return roles.stream()
                .map(Rol::getNombre)
                .collect(Collectors.toSet());
    }
}
