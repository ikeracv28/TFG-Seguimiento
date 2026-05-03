package com.tfg.api.services;

import com.tfg.api.models.dto.AusenciaRequest;
import com.tfg.api.models.dto.AusenciaResponse;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

public interface AusenciaService {

    AusenciaResponse registrar(AusenciaRequest request, String emailAlumno);

    List<AusenciaResponse> listarPorPractica(Long practicaId);

    AusenciaResponse obtenerPorId(Long id);

    AusenciaResponse revisar(Long id, String nuevoTipo, String comentario, String emailTutor);

    AusenciaResponse adjuntarJustificante(Long id, MultipartFile fichero, String emailAlumno) throws IOException;

    void eliminar(Long id, String emailAlumno);

    record JustificanteDto(byte[] datos, String mimeType, String nombreFichero) {}

    JustificanteDto descargarJustificante(Long id);
}
