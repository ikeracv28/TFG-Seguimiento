package com.tfg.api.services;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.NotificacionResponse;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.NotificacionRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class NotificacionServiceTest {

    @Autowired private NotificacionService notificacionService;
    @Autowired private NotificacionRepository notificacionRepository;
    @Autowired private UsuarioRepository usuarioRepository;

    private Usuario usuarioA;
    private Usuario usuarioB;

    private void setSecurityContext(String email) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, List.of()));
    }

    @BeforeEach
    void setUp() {
        usuarioA = usuarioRepository.save(Usuario.builder()
                .dni("11111111A").nombre("Usuario").apellidos("Uno")
                .email("usuarioa@test.com").passwordHash("hash").activo(true).build());
        usuarioB = usuarioRepository.save(Usuario.builder()
                .dni("22222222B").nombre("Usuario").apellidos("Dos")
                .email("usuariob@test.com").passwordHash("hash").activo(true).build());
    }

    // ─── crear ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Crear notificación guarda correctamente en BD")
    void crear_notificacion_persistida() {
        notificacionService.crear(usuarioA.getId(), "CHAT", "Nuevo mensaje de prueba");

        long count = notificacionRepository.countByUsuarioIdAndLeidaFalse(usuarioA.getId());
        assertThat(count).isEqualTo(1);
    }

    @Test
    @DisplayName("Crear notificación para usuario inexistente lanza excepción")
    void crear_usuario_inexistente_lanza_excepcion() {
        assertThatThrownBy(() -> notificacionService.crear(999999L, "CHAT", "Msg"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── listarParaUsuario ───────────────────────────────────────────────────

    @Test
    @DisplayName("listarParaUsuario devuelve solo las notificaciones del usuario autenticado")
    void listar_devuelve_solo_propias() {
        notificacionService.crear(usuarioA.getId(), "CHAT", "Para A");
        notificacionService.crear(usuarioA.getId(), "SEGUIMIENTO", "Para A también");
        notificacionService.crear(usuarioB.getId(), "CHAT", "Para B");

        setSecurityContext("usuarioa@test.com");
        List<NotificacionResponse> lista = notificacionService.listarParaUsuario();

        assertThat(lista).hasSize(2);
        assertThat(lista).allMatch(n -> n.tipo() != null);
    }

    @Test
    @DisplayName("listarParaUsuario devuelve lista vacía cuando no hay notificaciones")
    void listar_vacio_sin_notificaciones() {
        setSecurityContext("usuarioa@test.com");
        List<NotificacionResponse> lista = notificacionService.listarParaUsuario();

        assertThat(lista).isEmpty();
    }

    // ─── contarNoLeidas ──────────────────────────────────────────────────────

    @Test
    @DisplayName("contarNoLeidas devuelve número correcto")
    void contar_no_leidas_correcto() {
        notificacionService.crear(usuarioA.getId(), "CHAT", "Msg 1");
        notificacionService.crear(usuarioA.getId(), "EVALUACION", "Msg 2");

        setSecurityContext("usuarioa@test.com");
        long count = notificacionService.contarNoLeidas();

        assertThat(count).isEqualTo(2);
    }

    @Test
    @DisplayName("contarNoLeidas no cuenta notificaciones de otros usuarios")
    void contar_no_mezcla_usuarios() {
        notificacionService.crear(usuarioB.getId(), "CHAT", "Para B");

        setSecurityContext("usuarioa@test.com");
        long count = notificacionService.contarNoLeidas();

        assertThat(count).isEqualTo(0);
    }

    // ─── marcarLeida ─────────────────────────────────────────────────────────

    @Test
    @DisplayName("marcarLeida deja la notificación como leída")
    void marcar_leida_funciona() {
        notificacionService.crear(usuarioA.getId(), "CHAT", "Msg");
        setSecurityContext("usuarioa@test.com");
        Long notifId = notificacionService.listarParaUsuario().getFirst().id();

        notificacionService.marcarLeida(notifId);

        long noLeidas = notificacionService.contarNoLeidas();
        assertThat(noLeidas).isEqualTo(0);
    }

    @Test
    @DisplayName("marcarLeida de notificación ajena lanza excepción (A01-IDOR)")
    void marcar_leida_ajena_lanza_excepcion() {
        // Crear notificación para B
        notificacionService.crear(usuarioB.getId(), "CHAT", "Para B");
        Long notifIdDeB = notificacionRepository
                .findByUsuarioIdOrderByFechaCreacionDesc(usuarioB.getId())
                .getFirst().getId();

        // Usuario A intenta marcarla como leída
        setSecurityContext("usuarioa@test.com");
        assertThatThrownBy(() -> notificacionService.marcarLeida(notifIdDeB))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── marcarTodasLeidas ───────────────────────────────────────────────────

    @Test
    @DisplayName("marcarTodasLeidas deja todas en 0 no leídas")
    void marcar_todas_leidas_funciona() {
        notificacionService.crear(usuarioA.getId(), "CHAT", "Msg 1");
        notificacionService.crear(usuarioA.getId(), "CHAT", "Msg 2");
        notificacionService.crear(usuarioA.getId(), "CHAT", "Msg 3");

        setSecurityContext("usuarioa@test.com");
        notificacionService.marcarTodasLeidas();

        assertThat(notificacionService.contarNoLeidas()).isEqualTo(0);
    }

    @Test
    @DisplayName("marcarTodasLeidas no afecta notificaciones de otros usuarios")
    void marcar_todas_no_afecta_otros() {
        notificacionService.crear(usuarioB.getId(), "CHAT", "Para B");

        setSecurityContext("usuarioa@test.com");
        notificacionService.marcarTodasLeidas();

        long noLeidasB = notificacionRepository.countByUsuarioIdAndLeidaFalse(usuarioB.getId());
        assertThat(noLeidasB).isEqualTo(1);
    }
}
