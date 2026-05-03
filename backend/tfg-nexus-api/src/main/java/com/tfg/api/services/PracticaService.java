package com.tfg.api.services;

import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

/**
 * Interfaz de servicio para la gestión de prácticas académicas.
 */
public interface PracticaService {

    /**
     * Crea una nueva práctica académica.
     */
    PracticaResponse crear(PracticaRequest request);

    /**
     * Obtiene una práctica por su ID.
     */
    PracticaResponse obtenerPorId(Long id);

    /**
     * Obtiene todas las prácticas registradas de forma paginada.
     */
    Page<PracticaResponse> listarTodas(Pageable pageable);

    /**
     * Lista las prácticas asociadas a un alumno.
     */
    List<PracticaResponse> listarPorAlumno(Long alumnoId);

    /**
     * Actualiza los datos de una práctica existente.
     */
    PracticaResponse actualizar(Long id, PracticaRequest request);

    /**
     * Elimina una práctica si el estado lo permite.
     */
    void eliminar(Long id);

    /**
     * Cambia el estado de una práctica (ej: de BORRADOR a ACTIVA).
     */
    PracticaResponse cambiarEstado(Long id, String nuevoEstado);

    /**
     * Devuelve la práctica ACTIVA del alumno autenticado actualmente.
     */
    PracticaResponse obtenerPracticaActivaDelAlumno();

    /**
     * Lista las prácticas donde el tutor de empresa autenticado está asignado.
     */
    List<PracticaResponse> listarMisPracticasComoTutorEmpresa();

    /**
     * Lista las prácticas donde el tutor del centro autenticado está asignado.
     */
    List<PracticaResponse> listarMisPracticasComoTutorCentro();

    /**
     * Usado en SpEL: devuelve true si el alumno con alumnoId tiene el email del usuario autenticado.
     */
    boolean perteneceAlAlumnoAutenticado(Long alumnoId, String email);

    /**
     * Usado en SpEL: devuelve true si el usuario (por email) es alumno, tutor centro o tutor empresa de la práctica.
     */
    boolean esParticipante(Long practicaId, String email);
}
