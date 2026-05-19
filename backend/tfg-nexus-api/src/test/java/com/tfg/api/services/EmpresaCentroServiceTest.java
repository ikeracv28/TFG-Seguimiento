package com.tfg.api.services;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.entity.Centro;
import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.repository.CentroRepository;
import com.tfg.api.models.repository.EmpresaRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class EmpresaCentroServiceTest {

    @Autowired private EmpresaService empresaService;
    @Autowired private CentroService centroService;
    @Autowired private EmpresaRepository empresaRepository;
    @Autowired private CentroRepository centroRepository;

    // ─── EmpresaService ──────────────────────────────────────────────────────

    @Test
    @DisplayName("findAll empresas devuelve todas las empresas guardadas")
    void findAll_empresas_devuelve_lista() {
        empresaRepository.save(Empresa.builder()
                .nombre("Empresa A").cif("A11111111").build());
        empresaRepository.save(Empresa.builder()
                .nombre("Empresa B").cif("B22222222").build());

        List<EmpresaResponse> result = empresaService.findAll();

        assertThat(result).hasSizeGreaterThanOrEqualTo(2);
        assertThat(result).anyMatch(e -> e.nombre().equals("Empresa A"));
        assertThat(result).anyMatch(e -> e.nombre().equals("Empresa B"));
    }

    @Test
    @DisplayName("findAll empresas devuelve lista vacía si no hay empresas")
    void findAll_empresas_vacia() {
        List<EmpresaResponse> result = empresaService.findAll();
        assertThat(result).isNotNull();
    }

    // ─── CentroService ───────────────────────────────────────────────────────

    @Test
    @DisplayName("findAll centros devuelve todos los centros guardados")
    void findAll_centros_devuelve_lista() {
        centroRepository.save(Centro.builder()
                .nombre("IES Nexus").direccion("Calle Mayor 1").build());
        centroRepository.save(Centro.builder()
                .nombre("IES Altamira").direccion("Calle Secundaria 5").build());

        List<CentroResponse> result = centroService.findAll();

        assertThat(result).hasSizeGreaterThanOrEqualTo(2);
        assertThat(result).anyMatch(c -> c.nombre().equals("IES Nexus"));
    }

    @Test
    @DisplayName("findAll centros incluye los campos mapeados correctamente")
    void findAll_centros_campos_mapeados() {
        centroRepository.save(Centro.builder()
                .nombre("IES Test")
                .direccion("Calle Test 99")
                .telefono("600111222")
                .email("info@ies-test.edu")
                .build());

        List<CentroResponse> result = centroService.findAll();

        assertThat(result).anyMatch(c ->
                c.nombre().equals("IES Test") &&
                c.email().equals("info@ies-test.edu") &&
                c.telefono().equals("600111222"));
    }
}
