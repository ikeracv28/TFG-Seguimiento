package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
import com.tfg.api.models.entity.Practica;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

/**
 * Mapper para convertir entre Practica (Entidad JPA) y sus DTOs asociados.
 * Sigue el patrón establecido en UsuarioMapper.
 */
@Mapper(componentModel = "spring")
public interface PracticaMapper {

    /**
     * Convierte el DTO de creación en la entidad base.
     * Ignoramos las relaciones directas por ID, se cargarán en el Service.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "alumno", ignore = true)
    @Mapping(target = "tutorCentro", ignore = true)
    @Mapping(target = "tutorEmpresa", ignore = true)
    @Mapping(target = "empresa", ignore = true)
    @Mapping(target = "fechaCreacion", ignore = true)
    Practica toEntity(PracticaRequest request);

    /**
     * Convierte la entidad en una respuesta detallada (flattened).
     * Mapeamos manualmente los nombres para evitar que el Frontend 
     * tenga que hacer múltiples peticiones.
     */
    @Mapping(target = "alumnoId", source = "alumno.id")
    @Mapping(target = "alumnoNombre", expression = "java(practica.getAlumno().getNombre() + \" \" + practica.getAlumno().getApellidos())")
    @Mapping(target = "tutorCentroId", source = "tutorCentro.id")
    @Mapping(target = "tutorCentroNombre", expression = "java(practica.getTutorCentro().getNombre() + \" \" + practica.getTutorCentro().getApellidos())")
    @Mapping(target = "tutorEmpresaId", source = "tutorEmpresa.id")
    @Mapping(target = "tutorEmpresaNombre", expression = "java(practica.getTutorEmpresa().getNombre() + \" \" + practica.getTutorEmpresa().getApellidos())")
    @Mapping(target = "empresaId", source = "empresa.id")
    @Mapping(target = "empresaNombre", source = "empresa.nombre")
    PracticaResponse toResponse(Practica practica);

    /**
     * Convierte una lista de entidades en una lista de respuestas DTO.
     */
    List<PracticaResponse> toResponseList(List<Practica> practicas);
}
