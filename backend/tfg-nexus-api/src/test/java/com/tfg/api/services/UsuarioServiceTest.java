package com.tfg.api.services;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
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
class UsuarioServiceTest {

    @Autowired private UsuarioService usuarioService;
    @Autowired private UsuarioRepository usuarioRepository;

    private Usuario usuario;

    private void setSecurityContext(String email) {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(email, null, List.of()));
    }

    @BeforeEach
    void setUp() {
        usuario = usuarioRepository.save(Usuario.builder()
                .dni("12345678Z").nombre("Carlos").apellidos("García")
                .email("carlos@test.com").passwordHash("hash").activo(true).build());
    }

    // ─── getMe ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("getMe devuelve el perfil del usuario autenticado")
    void getMe_devuelve_perfil() {
        setSecurityContext("carlos@test.com");
        UsuarioResponse response = usuarioService.getMe();

        assertThat(response.email()).isEqualTo("carlos@test.com");
        assertThat(response.nombre()).isEqualTo("Carlos");
        assertThat(response.tieneFoto()).isFalse();
    }

    @Test
    @DisplayName("getMe lanza excepción si email no existe en BD")
    void getMe_usuario_inexistente_lanza_excepcion() {
        setSecurityContext("noexiste@test.com");
        assertThatThrownBy(() -> usuarioService.getMe())
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── uploadFoto ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("uploadFoto guarda la imagen del usuario")
    void upload_foto_guarda_imagen() {
        setSecurityContext("carlos@test.com");
        MockMultipartFile foto = new MockMultipartFile(
                "file", "foto.jpg", "image/jpeg", new byte[]{1, 2, 3});

        usuarioService.uploadFoto(foto);

        Usuario actualizado = usuarioRepository.findByEmail("carlos@test.com").orElseThrow();
        assertThat(actualizado.getFotoPerfil()).isNotNull();
        assertThat(actualizado.getFotoContentType()).isEqualTo("image/jpeg");
    }

    @Test
    @DisplayName("uploadFoto con tipo no permitido lanza excepción")
    void upload_tipo_no_permitido_lanza_excepcion() {
        setSecurityContext("carlos@test.com");
        MockMultipartFile gif = new MockMultipartFile(
                "file", "foto.gif", "image/gif", new byte[]{1, 2, 3});

        assertThatThrownBy(() -> usuarioService.uploadFoto(gif))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("no permitido");
    }

    @Test
    @DisplayName("uploadFoto con archivo demasiado grande lanza excepción")
    void upload_archivo_grande_lanza_excepcion() {
        setSecurityContext("carlos@test.com");
        byte[] bigFile = new byte[6 * 1024 * 1024]; // 6 MB
        MockMultipartFile foto = new MockMultipartFile("file", "foto.jpg", "image/jpeg", bigFile);

        assertThatThrownBy(() -> usuarioService.uploadFoto(foto))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("uploadFoto acepta PNG y WebP")
    void upload_acepta_png_y_webp() {
        setSecurityContext("carlos@test.com");
        MockMultipartFile png = new MockMultipartFile(
                "file", "foto.png", "image/png", new byte[]{1, 2, 3});

        usuarioService.uploadFoto(png);

        Usuario actualizado = usuarioRepository.findByEmail("carlos@test.com").orElseThrow();
        assertThat(actualizado.getFotoContentType()).isEqualTo("image/png");
    }

    // ─── getFoto ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("getFoto devuelve bytes de la foto guardada")
    void getFoto_devuelve_bytes() {
        setSecurityContext("carlos@test.com");
        usuarioService.uploadFoto(new MockMultipartFile(
                "file", "foto.jpg", "image/jpeg", new byte[]{10, 20, 30}));

        byte[] foto = usuarioService.getFoto(usuario.getId());
        assertThat(foto).isEqualTo(new byte[]{10, 20, 30});
    }

    @Test
    @DisplayName("getFoto lanza excepción si el usuario no tiene foto")
    void getFoto_sin_foto_lanza_excepcion() {
        assertThatThrownBy(() -> usuarioService.getFoto(usuario.getId()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("foto");
    }

    @Test
    @DisplayName("getFoto lanza excepción si el usuario no existe")
    void getFoto_usuario_inexistente_lanza_excepcion() {
        assertThatThrownBy(() -> usuarioService.getFoto(999999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ─── getFotoContentType ──────────────────────────────────────────────────

    @Test
    @DisplayName("getFotoContentType devuelve el tipo MIME guardado")
    void getFotoContentType_devuelve_mime() {
        setSecurityContext("carlos@test.com");
        usuarioService.uploadFoto(new MockMultipartFile(
                "file", "foto.png", "image/png", new byte[]{1}));

        String contentType = usuarioService.getFotoContentType(usuario.getId());
        assertThat(contentType).isEqualTo("image/png");
    }

    @Test
    @DisplayName("getFotoContentType devuelve image/jpeg por defecto si no hay tipo guardado")
    void getFotoContentType_por_defecto_jpeg() {
        String contentType = usuarioService.getFotoContentType(usuario.getId());
        assertThat(contentType).isEqualTo("image/jpeg");
    }
}
