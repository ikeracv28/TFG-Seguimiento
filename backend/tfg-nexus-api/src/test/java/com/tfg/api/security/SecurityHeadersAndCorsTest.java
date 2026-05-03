package com.tfg.api.security;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * [A05] Cabeceras de seguridad HTTP.
 * [A01] CORS sin wildcard y con credenciales.
 *
 * Usa GET /api/v1/practicas (devuelve 401) para las pruebas de cabeceras —
 * evita consumir el rate limit del endpoint /auth/.
 * Usa OPTIONS /api/v1/practicas para las pruebas de CORS.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityHeadersAndCorsTest {

    @Autowired
    private MockMvc mockMvc;

    // ---- Cabeceras de seguridad HTTP (A05) ----

    @Test
    @DisplayName("[A05] X-Frame-Options: DENY — previene clickjacking")
    void response_has_x_frame_options_deny() throws Exception {
        mockMvc.perform(get("/api/v1/practicas"))
                .andExpect(header().string("X-Frame-Options", "DENY"));
    }

    @Test
    @DisplayName("[A05] X-Content-Type-Options: nosniff — previene MIME sniffing")
    void response_has_x_content_type_nosniff() throws Exception {
        mockMvc.perform(get("/api/v1/practicas"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"));
    }

    @Test
    @DisplayName("[A05] X-XSS-Protection presente en la respuesta")
    void response_has_xss_protection_header() throws Exception {
        mockMvc.perform(get("/api/v1/practicas"))
                .andExpect(header().exists("X-XSS-Protection"));
    }

    @Test
    @DisplayName("[A05] Cabeceras de seguridad presentes en respuestas de error de autenticación")
    void security_headers_present_on_auth_error_response() throws Exception {
        // Spring Security devuelve 403 sin AuthenticationEntryPoint explícito; lo importante son las cabeceras
        mockMvc.perform(get("/api/v1/practicas"))
                .andExpect(status().is4xxClientError())
                .andExpect(header().exists("X-Frame-Options"))
                .andExpect(header().exists("X-Content-Type-Options"));
    }

    // ---- CORS sin wildcard (A01) ----

    @Test
    @DisplayName("[A01] Preflight desde origen permitido (localhost:3000) devuelve Access-Control-Allow-Origin")
    void preflight_from_allowed_origin_returns_cors_header() throws Exception {
        mockMvc.perform(options("/api/v1/practicas")
                .header("Origin", "http://localhost:3000")
                .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
    }

    @Test
    @DisplayName("[A01] Preflight desde origen permitido (localhost:8080) también funciona")
    void preflight_from_localhost_8080_works() throws Exception {
        mockMvc.perform(options("/api/v1/practicas")
                .header("Origin", "http://localhost:8080")
                .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:8080"));
    }

    @Test
    @DisplayName("[A01] CORS no usa wildcard — Access-Control-Allow-Origin nunca es '*'")
    void cors_never_returns_wildcard() throws Exception {
        mockMvc.perform(options("/api/v1/practicas")
                .header("Origin", "http://localhost:3000")
                .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().string("Access-Control-Allow-Origin", not("*")));
    }

    @Test
    @DisplayName("[A01] CORS permite credenciales (Access-Control-Allow-Credentials: true)")
    void cors_allows_credentials() throws Exception {
        mockMvc.perform(options("/api/v1/practicas")
                .header("Origin", "http://localhost:3000")
                .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().string("Access-Control-Allow-Credentials", "true"));
    }

    @Test
    @DisplayName("[A01] Preflight desde origen no autorizado no devuelve cabecera CORS")
    void preflight_from_unauthorized_origin_has_no_cors_header() throws Exception {
        mockMvc.perform(options("/api/v1/practicas")
                .header("Origin", "http://evil-site.com")
                .header("Access-Control-Request-Method", "GET"))
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }
}
