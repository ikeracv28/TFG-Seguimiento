package com.tfg.api.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private static final String RESEND_URL = "https://api.resend.com/emails";

    @Value("${resend.api-key:}")
    private String apiKey;

    @Value("${resend.from:Nexus FP <onboarding@resend.dev>}")
    private String fromAddress;

    private final RestClient restClient = RestClient.create();

    public void enviarCredenciales(String destinatario, String nombre, String email, String password) {
        if (apiKey == null || apiKey.isBlank()) {
            log.info("EMAIL_SKIP (Resend no configurado) — destinatario={} email={} password={}",
                    destinatario, email, password);
            return;
        }
        enviar(destinatario, "Tus credenciales de acceso a Nexus FP",
                buildHtmlCredenciales(nombre, email, password));
    }

    public void enviarConvocatoriaTutoria(String destinatario, String nombreAlumno,
                                          LocalDateTime fechaHora, String nombreTutor) {
        if (apiKey == null || apiKey.isBlank()) {
            log.info("EMAIL_SKIP tutoria — alumno={} hora={}", destinatario, fechaHora);
            return;
        }
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("EEEE d 'de' MMMM · HH:mm'h'",
                new Locale("es", "ES"));
        String fechaFormateada = fechaHora.format(fmt);
        enviar(destinatario, "Tutoría FCT — " + fechaFormateada,
                buildHtmlTutoria(nombreAlumno, fechaFormateada, nombreTutor));
    }

    private void enviar(String destinatario, String asunto, String html) {
        try {
            var body = Map.of(
                    "from", fromAddress,
                    "to", List.of(destinatario),
                    "subject", asunto,
                    "html", html
            );
            restClient.post()
                    .uri(RESEND_URL)
                    .header("Authorization", "Bearer " + apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toBodilessEntity();
            log.info("EMAIL_ENVIADO destinatario={}", destinatario);
        } catch (Exception ex) {
            log.warn("EMAIL_ERROR destinatario={} motivo={}", destinatario, ex.getMessage());
        }
    }

    private String buildHtmlCredenciales(String nombre, String email, String password) {
        return """
            <html><body style="font-family:Arial,sans-serif;color:#222;max-width:500px;margin:auto">
              <h2 style="color:#2563EB">Bienvenido/a a Nexus FP</h2>
              <p>Hola <strong>%s</strong>,</p>
              <p>Se ha creado una cuenta para ti en la plataforma Nexus de gestión de prácticas.</p>
              <table style="border-collapse:collapse;width:100%%">
                <tr><td style="padding:8px;background:#F3F4F6;font-weight:bold">Email</td>
                    <td style="padding:8px">%s</td></tr>
                <tr><td style="padding:8px;background:#F3F4F6;font-weight:bold">Contraseña</td>
                    <td style="padding:8px"><code>%s</code></td></tr>
              </table>
              <p style="color:#6B7280;font-size:13px;margin-top:24px">
                Por seguridad, cambia tu contraseña en el primer acceso.<br>
                Accede en: <a href="https://nexusfp.up.railway.app">nexusfp.up.railway.app</a>
              </p>
            </body></html>
            """.formatted(nombre, email, password);
    }

    private String buildHtmlTutoria(String nombre, String fechaFormateada, String tutor) {
        return """
            <html><body style="font-family:Arial,sans-serif;color:#222;max-width:500px;margin:auto">
              <h2 style="color:#2563EB">Tutoría FCT — Nexus</h2>
              <p>Hola <strong>%s</strong>,</p>
              <p>Tu tutor de centro ha programado una sesión de tutoría contigo:</p>
              <div style="background:#F3F4F6;border-left:4px solid #2563EB;padding:16px;margin:16px 0">
                <p style="margin:0;font-size:18px;font-weight:bold">%s</p>
                <p style="margin:4px 0 0;color:#6B7280">Duración: 15 minutos</p>
              </div>
              <p>Tutor: <strong>%s</strong></p>
              <p style="color:#6B7280;font-size:13px">
                Accede en: <a href="https://nexusfp.up.railway.app">nexusfp.up.railway.app</a>
              </p>
            </body></html>
            """.formatted(nombre, fechaFormateada, tutor);
    }
}
