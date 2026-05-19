package com.tfg.api.controllers;

import com.tfg.api.models.dto.MensajeRequest;
import com.tfg.api.models.dto.MensajeResponse;
import com.tfg.api.services.MensajeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/mensajes")
@RequiredArgsConstructor
public class MensajeController {

    private final MensajeService mensajeService;
    private final SimpMessagingTemplate messagingTemplate;

    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<MensajeResponse>> historial(
            @PathVariable Long practicaId,
            @RequestParam(defaultValue = "ALUMNO") String canal) {
        return ResponseEntity.ok(mensajeService.listarPorPractica(practicaId, canal));
    }

    /** Canal alumno ↔ tutor centro */
    @MessageMapping("/chat/{practicaId}")
    public void enviarMensajeAlumno(
            @DestinationVariable Long practicaId,
            @Payload MensajeRequest request,
            Principal principal) {
        if (principal == null) return;
        MensajeResponse resp = mensajeService.guardar(request, principal.getName(), practicaId, "ALUMNO");
        messagingTemplate.convertAndSend("/topic/practica/" + practicaId, resp);
    }

    /** Canal tutor empresa ↔ tutor centro */
    @MessageMapping("/chat/{practicaId}/tutores")
    public void enviarMensajeTutores(
            @DestinationVariable Long practicaId,
            @Payload MensajeRequest request,
            Principal principal) {
        if (principal == null) return;
        MensajeResponse resp = mensajeService.guardar(request, principal.getName(), practicaId, "TUTORES");
        messagingTemplate.convertAndSend("/topic/practica/" + practicaId + "/tutores", resp);
    }

    @PostMapping("/practica/{practicaId}/adjunto")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<MensajeResponse> subirAdjunto(
            @PathVariable Long practicaId,
            @RequestParam(defaultValue = "ALUMNO") String canal,
            @RequestParam("fichero") MultipartFile fichero,
            Principal principal) throws IOException {

        MensajeResponse resp = mensajeService.guardarAdjunto(
                practicaId, canal, principal.getName(),
                fichero.getBytes(), fichero.getOriginalFilename(), fichero.getContentType());

        String topic = "TUTORES".equalsIgnoreCase(canal)
                ? "/topic/practica/" + practicaId + "/tutores"
                : "/topic/practica/" + practicaId;
        messagingTemplate.convertAndSend(topic, resp);

        return ResponseEntity.ok(resp);
    }

    @GetMapping("/{mensajeId}/adjunto")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<byte[]> descargarAdjunto(
            @PathVariable Long mensajeId,
            Principal principal) {
        return mensajeService.descargarAdjunto(mensajeId, principal.getName());
    }
}
