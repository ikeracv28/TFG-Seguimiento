package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.AusenciaRequest;
import com.tfg.api.models.dto.AusenciaResponse;
import com.tfg.api.models.entity.Ausencia;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.mapper.AusenciaMapper;
import com.tfg.api.models.repository.AusenciaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.AusenciaService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class AusenciaServiceImpl implements AusenciaService {

    private static final Logger log = LoggerFactory.getLogger(AusenciaServiceImpl.class);
    private static final Set<String> TIPOS_REVISION = Set.of("JUSTIFICADA", "INJUSTIFICADA");
    private static final Set<String> MIME_PERMITIDOS = Set.of(
            "application/pdf", "image/jpeg", "image/png", "image/jpg");
    private static final long MAX_BYTES = 5 * 1024 * 1024L; // 5 MB

    private final AusenciaRepository ausenciaRepository;
    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final AusenciaMapper ausenciaMapper;
    private final AuditService auditService;

    @Override
    @Transactional
    public AusenciaResponse registrar(AusenciaRequest request, String emailAlumno) {
        Usuario alumno = usuarioRepository.findByEmail(emailAlumno)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Practica practica = practicaRepository.findById(request.practicaId())
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        // A01: el alumno solo puede registrar ausencias en su propia práctica
        if (!practica.getAlumno().getId().equals(alumno.getId())) {
            throw new BusinessRuleException("No tienes acceso a esta práctica");
        }
        if (!"ACTIVA".equals(practica.getEstado())) {
            throw new BusinessRuleException("Solo se pueden registrar ausencias en prácticas activas");
        }

        // A04: sin duplicados por fecha
        if (ausenciaRepository.existsByPracticaIdAndFecha(request.practicaId(), request.fecha())) {
            throw new BusinessRuleException("Ya existe una ausencia registrada para esa fecha");
        }

        Ausencia ausencia = Ausencia.builder()
                .practica(practica)
                .fecha(request.fecha())
                .motivo(request.motivo())
                .tipo("PENDIENTE")
                .registradaPor(alumno)
                .build();

        log.info("AUSENCIA_REGISTRADA practica={} alumno={} fecha={}", practica.getId(), alumno.getId(), request.fecha());
        AusenciaResponse resp = ausenciaMapper.toResponse(ausenciaRepository.save(ausencia));
        auditService.registrar("AUSENCIAS", "REGISTRAR", resp.id(),
                "Fecha=" + request.fecha() + " practica=" + practica.getId(), emailAlumno);
        return resp;
    }

    @Override
    @Transactional(readOnly = true)
    public List<AusenciaResponse> listarPorPractica(Long practicaId) {
        return ausenciaMapper.toResponseList(
                ausenciaRepository.findByPracticaIdOrderByFechaDesc(practicaId));
    }

    @Override
    @Transactional(readOnly = true)
    public AusenciaResponse obtenerPorId(Long id) {
        return ausenciaMapper.toResponse(
                ausenciaRepository.findById(id)
                        .orElseThrow(() -> new ResourceNotFoundException("Ausencia no encontrada")));
    }

    @Override
    @Transactional
    public AusenciaResponse revisar(Long id, String nuevoTipo, String comentario, String emailTutor) {
        Ausencia ausencia = ausenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ausencia no encontrada"));

        if (!"PENDIENTE".equals(ausencia.getTipo())) {
            throw new BusinessRuleException("Esta ausencia ya fue revisada");
        }
        if (!TIPOS_REVISION.contains(nuevoTipo)) {
            throw new BusinessRuleException("Tipo no válido. Use: JUSTIFICADA o INJUSTIFICADA");
        }

        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        // A01: el tutor empresa solo puede revisar ausencias de sus propias prácticas
        Practica practica = ausencia.getPractica();
        if (practica.getTutorEmpresa() == null || !practica.getTutorEmpresa().getId().equals(tutor.getId())) {
            throw new BusinessRuleException("No tienes permiso para revisar ausencias de esta práctica");
        }

        ausencia.setTipo(nuevoTipo);
        ausencia.setRevisadaPor(tutor);
        ausencia.setComentarioRevision(comentario);

        log.info("AUSENCIA_REVISADA id={} tipo={} por={}", id, nuevoTipo, emailTutor);
        AusenciaResponse revisada = ausenciaMapper.toResponse(ausenciaRepository.save(ausencia));
        auditService.registrar("AUSENCIAS", "REVISAR_" + nuevoTipo, id,
                "Ausencia revisada como " + nuevoTipo, emailTutor);
        return revisada;
    }

    @Override
    @Transactional
    public AusenciaResponse adjuntarJustificante(Long id, MultipartFile fichero, String emailAlumno) throws IOException {
        Ausencia ausencia = ausenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ausencia no encontrada"));

        // A01: solo el alumno que registró puede adjuntar
        if (!ausencia.getRegistradaPor().getEmail().equals(emailAlumno)) {
            throw new BusinessRuleException("No tienes permiso para modificar esta ausencia");
        }
        if (!"PENDIENTE".equals(ausencia.getTipo())) {
            throw new BusinessRuleException("No se puede adjuntar justificante a una ausencia ya revisada");
        }
        if (fichero.getSize() > MAX_BYTES) {
            throw new BusinessRuleException("El fichero no puede superar los 5 MB");
        }
        String mime = fichero.getContentType();
        if (mime == null || !MIME_PERMITIDOS.contains(mime)) {
            throw new BusinessRuleException("Solo se permiten ficheros PDF, JPG o PNG");
        }

        ausencia.setJustificante(fichero.getBytes());
        ausencia.setNombreFichero(fichero.getOriginalFilename());
        ausencia.setMimeType(mime);

        AusenciaResponse conJustificante = ausenciaMapper.toResponse(ausenciaRepository.save(ausencia));
        auditService.registrar("AUSENCIAS", "ADJUNTAR_JUSTIFICANTE", id,
                "Fichero=" + fichero.getOriginalFilename(), emailAlumno);
        return conJustificante;
    }

    @Override
    @Transactional(readOnly = true)
    public AusenciaService.JustificanteDto descargarJustificante(Long id) {
        Ausencia ausencia = ausenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ausencia no encontrada"));
        if (ausencia.getJustificante() == null || ausencia.getJustificante().length == 0) {
            throw new ResourceNotFoundException("Esta ausencia no tiene justificante adjunto");
        }
        return new AusenciaService.JustificanteDto(
                ausencia.getJustificante(),
                ausencia.getMimeType(),
                ausencia.getNombreFichero());
    }

    @Override
    @Transactional
    public void eliminar(Long id, String emailAlumno) {
        Ausencia ausencia = ausenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ausencia no encontrada"));

        // A01: solo el alumno propietario puede eliminar
        if (!ausencia.getRegistradaPor().getEmail().equals(emailAlumno)) {
            throw new BusinessRuleException("No tienes permiso para eliminar esta ausencia");
        }
        if (!"PENDIENTE".equals(ausencia.getTipo())) {
            throw new BusinessRuleException("No se puede eliminar una ausencia ya revisada");
        }

        auditService.registrar("AUSENCIAS", "ELIMINAR", id,
                "Ausencia eliminada por alumno", emailAlumno);
        ausenciaRepository.delete(ausencia);
        log.info("AUSENCIA_ELIMINADA id={} por={}", id, emailAlumno);
    }
}
