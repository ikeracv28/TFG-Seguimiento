package com.tfg.api.services;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromAddress;

    public void enviarCredenciales(String destinatario, String nombre, String email, String password) {
        if (fromAddress == null || fromAddress.isBlank()) {
            log.info("EMAIL_SKIP (SMTP no configurado) — destinatario={} nombre={} email={} password={}",
                    destinatario, nombre, email, password);
            return;
        }
        try {
            final var msg = mailSender.createMimeMessage();
            final var helper = new MimeMessageHelper(msg, true, "UTF-8");
            helper.setFrom(fromAddress);
            helper.setTo(destinatario);
            helper.setSubject("Tus credenciales de acceso a Nexus FP");
            helper.setText(buildHtml(nombre, email, password), true);
            mailSender.send(msg);
            log.info("EMAIL_ENVIADO destinatario={}", destinatario);
        } catch (Exception ex) {
            log.warn("EMAIL_ERROR destinatario={} motivo={}", destinatario, ex.getMessage());
        }
    }

    private String buildHtml(String nombre, String email, String password) {
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
}
