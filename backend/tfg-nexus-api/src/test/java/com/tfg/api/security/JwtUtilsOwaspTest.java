package com.tfg.api.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * [A02] Verifica que JwtUtils usa Decoders.BASE64.decode() en lugar de getBytes().
 * Test unitario — sin contexto Spring.
 */
class JwtUtilsOwaspTest {

    // Base64 de 'secretkeyfortfgnexus2026securedevelopment' (40 bytes, válido para HMAC-SHA256)
    private static final String SECRET_BASE64_VALIDO =
            "c2VjcmV0a2V5Zm9ydGZnbmV4dXMyMDI2c2VjdXJlZGV2ZWxvcG1lbnQ=";

    private JwtUtils buildJwtUtils(String secret) {
        JwtUtils utils = new JwtUtils();
        ReflectionTestUtils.setField(utils, "secret", secret);
        ReflectionTestUtils.setField(utils, "expiration", 86400000L);
        return utils;
    }

    @Test
    @DisplayName("[A02] Secret Base64 válido genera token sin excepción")
    void base64_secret_generates_token() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails user = User.withUsername("alumno@nexus.edu")
                .password("hash").authorities(Collections.emptyList()).build();

        String token = utils.generateToken(user);
        assertThat(token).isNotBlank();
    }

    @Test
    @DisplayName("[A02] Token generado se valida correctamente contra el mismo secret")
    void generated_token_validates_correctly() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails user = User.withUsername("tutor@nexus.edu")
                .password("hash").authorities(Collections.emptyList()).build();

        String token = utils.generateToken(user);
        assertThat(utils.validateToken(token, user)).isTrue();
    }

    @Test
    @DisplayName("[A02] Username extraído del token coincide con el original")
    void extracted_username_matches_original() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails user = User.withUsername("admin@nexus.edu")
                .password("hash").authorities(Collections.emptyList()).build();

        String token = utils.generateToken(user);
        assertThat(utils.extractUsername(token)).isEqualTo("admin@nexus.edu");
    }

    @Test
    @DisplayName("[A02] Token de usuario A no valida contra usuario B")
    void token_from_user_a_does_not_validate_for_user_b() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails userA = User.withUsername("a@nexus.edu").password("h").authorities(Collections.emptyList()).build();
        UserDetails userB = User.withUsername("b@nexus.edu").password("h").authorities(Collections.emptyList()).build();

        String tokenA = utils.generateToken(userA);
        assertThat(utils.validateToken(tokenA, userB)).isFalse();
    }

    @Test
    @DisplayName("[A02] Secret con caracteres no-Base64 lanza excepción al intentar firmar")
    void non_base64_secret_throws_on_sign() {
        // "CAMBIAR_EN_PRODUCCION" contiene '_' que no es Base64 estándar
        JwtUtils utils = buildJwtUtils("CAMBIAR_EN_PRODUCCION");
        UserDetails user = User.withUsername("any@test.com")
                .password("hash").authorities(Collections.emptyList()).build();

        assertThatThrownBy(() -> utils.generateToken(user))
                .isInstanceOf(Exception.class);
    }

    @Test
    @DisplayName("[A07] Token generado incluye JTI único no nulo (necesario para blacklist de logout)")
    void generated_token_contains_non_null_jti() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails user = User.withUsername("alumno@nexus.edu")
                .password("hash").authorities(Collections.emptyList()).build();

        String token = utils.generateToken(user);
        String jti = utils.extractJti(token);

        assertThat(jti).isNotBlank();
    }

    @Test
    @DisplayName("[A07] Dos tokens distintos tienen JTIs distintos (no reutilizables)")
    void two_tokens_have_different_jtis() {
        JwtUtils utils = buildJwtUtils(SECRET_BASE64_VALIDO);
        UserDetails user = User.withUsername("alumno@nexus.edu")
                .password("hash").authorities(Collections.emptyList()).build();

        String jti1 = utils.extractJti(utils.generateToken(user));
        String jti2 = utils.extractJti(utils.generateToken(user));

        assertThat(jti1).isNotEqualTo(jti2);
    }
}
