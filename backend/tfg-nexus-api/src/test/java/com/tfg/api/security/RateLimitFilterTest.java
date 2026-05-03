package com.tfg.api.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * [A04] Verifica el rate limiting en endpoints de autenticación.
 * Test unitario — instancia el filtro directamente sin contexto Spring.
 */
class RateLimitFilterTest {

    private RateLimitFilter filter;

    @BeforeEach
    void setUp() {
        filter = new RateLimitFilter();
    }

    private int doRequest(String ip, String uri) throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setRemoteAddr(ip);
        req.setRequestURI(uri);
        MockHttpServletResponse resp = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();
        filter.doFilter(req, resp, chain);
        return resp.getStatus();
    }

    @Test
    @DisplayName("[A04] Las primeras 10 peticiones al endpoint /auth/ se permiten")
    void first_10_requests_to_auth_are_allowed() throws Exception {
        String ip = "10.1.1.1";
        for (int i = 0; i < 10; i++) {
            assertThat(doRequest(ip, "/api/v1/auth/login"))
                    .as("Petición %d debería ser permitida", i + 1)
                    .isEqualTo(200);
        }
    }

    @Test
    @DisplayName("[A04] La petición 11 desde la misma IP devuelve 429 Too Many Requests")
    void eleventh_request_returns_429() throws Exception {
        String ip = "10.1.1.2";
        for (int i = 0; i < 10; i++) {
            doRequest(ip, "/api/v1/auth/login");
        }
        assertThat(doRequest(ip, "/api/v1/auth/login")).isEqualTo(429);
    }

    @Test
    @DisplayName("[A04] Petición 429 incluye body JSON con mensaje de error")
    void rate_limit_response_has_json_body() throws Exception {
        String ip = "10.1.1.3";
        for (int i = 0; i < 10; i++) {
            doRequest(ip, "/api/v1/auth/register");
        }
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.setRemoteAddr(ip);
        req.setRequestURI("/api/v1/auth/register");
        MockHttpServletResponse resp = new MockHttpServletResponse();
        filter.doFilter(req, resp, new MockFilterChain());

        assertThat(resp.getStatus()).isEqualTo(429);
        assertThat(resp.getContentAsString()).contains("429");
    }

    @Test
    @DisplayName("[A04] Endpoints fuera de /auth/ no tienen rate limiting")
    void non_auth_endpoints_are_not_rate_limited() throws Exception {
        String ip = "10.1.1.4";
        for (int i = 0; i < 20; i++) {
            assertThat(doRequest(ip, "/api/v1/practicas"))
                    .as("Petición %d a /practicas debería pasar siempre", i + 1)
                    .isEqualTo(200);
        }
    }

    @Test
    @DisplayName("[A04] IPs distintas tienen límites independientes")
    void different_ips_have_independent_rate_limits() throws Exception {
        // IP A agota su límite
        for (int i = 0; i < 10; i++) {
            doRequest("10.1.1.5", "/api/v1/auth/login");
        }
        assertThat(doRequest("10.1.1.5", "/api/v1/auth/login")).isEqualTo(429);

        // IP B aún tiene su límite completo
        assertThat(doRequest("10.1.1.6", "/api/v1/auth/login")).isEqualTo(200);
    }

    @Test
    @DisplayName("[A04] El registro también está sujeto al rate limiting")
    void register_endpoint_also_rate_limited() throws Exception {
        String ip = "10.1.1.7";
        for (int i = 0; i < 10; i++) {
            doRequest(ip, "/api/v1/auth/register");
        }
        assertThat(doRequest(ip, "/api/v1/auth/register")).isEqualTo(429);
    }
}
