package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.IncidenciaResponse;
import com.tfg.api.models.entity.Incidencia;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface IncidenciaMapper {

    @Mapping(target = "practicaId", source = "practica.id")
    @Mapping(target = "creadaPorId", source = "creadaPor.id")
    @Mapping(target = "creadaPorNombre",
            expression = "java(incidencia.getCreadaPor().getNombre() + \" \" + incidencia.getCreadaPor().getApellidos())")
    @Mapping(target = "resueltaPorNombre",
            expression = "java(incidencia.getResueltaPor() != null ? incidencia.getResueltaPor().getNombre() + \" \" + incidencia.getResueltaPor().getApellidos() : null)")
    @Mapping(target = "fechaResolucion", source = "fechaResolucion")
    IncidenciaResponse toResponse(Incidencia incidencia);

    List<IncidenciaResponse> toResponseList(List<Incidencia> incidencias);
}
