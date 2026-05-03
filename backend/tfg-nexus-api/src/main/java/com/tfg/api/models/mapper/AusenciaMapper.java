package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.AusenciaResponse;
import com.tfg.api.models.entity.Ausencia;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface AusenciaMapper {

    @Mapping(target = "practicaId",         source = "practica.id")
    @Mapping(target = "tieneJustificante",  expression = "java(ausencia.getJustificante() != null && ausencia.getJustificante().length > 0)")
    @Mapping(target = "registradaPorId",    source = "registradaPor.id")
    @Mapping(target = "registradaPorNombre",
             expression = "java(ausencia.getRegistradaPor().getNombre() + \" \" + ausencia.getRegistradaPor().getApellidos())")
    @Mapping(target = "revisadaPorId",      source = "revisadaPor.id")
    @Mapping(target = "revisadaPorNombre",
             expression = "java(ausencia.getRevisadaPor() != null ? ausencia.getRevisadaPor().getNombre() + \" \" + ausencia.getRevisadaPor().getApellidos() : null)")
    AusenciaResponse toResponse(Ausencia ausencia);

    List<AusenciaResponse> toResponseList(List<Ausencia> ausencias);
}
