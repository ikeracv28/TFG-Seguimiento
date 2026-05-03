package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.models.entity.Seguimiento;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

/**
 * Mapper para la conversión entre Seguimiento (Entidad JPA) y DTOs.
 * Gestiona la lógica de transformación de identidades y nombres.
 */
@Mapper(componentModel = "spring")
public interface SeguimientoMapper {

    /**
     * Mapea los datos de entrada a una entidad de base de datos.
     * El ID de la práctica se gestionará en la lógica de servicio.
     */
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "practica", ignore = true)
    @Mapping(target = "estado", ignore = true)
    @Mapping(target = "validadoPor", ignore = true)
    @Mapping(target = "comentarioTutor", ignore = true)
    @Mapping(target = "fechaCreacion", ignore = true)
    Seguimiento toEntity(SeguimientoRequest request);

    /**
     * Mapea una entidad guardada a una respuesta para el frontend.
     */
    @Mapping(target = "practicaId", source = "practica.id")
    @Mapping(target = "validadoPorId", source = "validadoPor.id")
    @Mapping(target = "validadoPorNombre", expression = "java(seguimiento.getValidadoPor() != null ? seguimiento.getValidadoPor().getNombre() + \" \" + seguimiento.getValidadoPor().getApellidos() : null)")
    SeguimientoResponse toResponse(Seguimiento seguimiento);
}
