package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.AuthResponse;
import com.tfg.api.models.dto.LoginRequest;
import com.tfg.api.models.dto.RegisterRequest;
import com.tfg.api.models.entity.Rol;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.mapper.UsuarioMapper;
import com.tfg.api.models.repository.RolRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.security.JwtUtils;
import com.tfg.api.security.UserDetailsServiceImpl;
import com.tfg.api.services.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;

/**
 * Implementación de la lógica de autenticación real para Nexus-TFG.
 */
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final AuthenticationManager authenticationManager;
    private final UsuarioMapper usuarioMapper;
    private final UserDetailsServiceImpl userDetailsService;

    /**
     * Registra al usuario y devuelve automáticamente el Token para el Login inmediato.
     */
    @Override
    @Transactional
    public AuthResponse registrar(RegisterRequest request) {

        // Validaciones de integridad (DNI y Email únicos)
        validarUnicidad(request);

        // Uso del Mapper para convertir DTO a Entidad
        Usuario usuario = usuarioMapper.registerToEntity(request);
        
        // Encriptación de contraseña (Lógica centralizada aquí por seguridad)
        usuario.setPasswordHash(passwordEncoder.encode(request.password()));

        // Asignación de rol base
        Rol rolAlumno = rolRepository.findByNombre("ROLE_ALUMNO")
                .orElseThrow(() -> new BusinessRuleException("Error: El rol de Alumno no está configurado en el sistema"));
        
        usuario.setRoles(Collections.singleton(rolAlumno));
        usuario.setActivo(true);

        // Persistencia
        Usuario usuarioGuardado = usuarioRepository.save(usuario);

        // CARGA DE USERDETAILS PARA JWT (Corrección de tipo)
        UserDetails userDetails = userDetailsService.loadUserByUsername(usuarioGuardado.getEmail());
        String token = jwtUtils.generateToken(userDetails);

        return usuarioMapper.toAuthResponse(usuarioGuardado, token);
    }

    /**
     * Proceso de Login oficial.
     */
    @Override
    public AuthResponse login(LoginRequest request) {
        
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        Usuario usuario = usuarioRepository.findByEmail(request.email())
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con el email: " + request.email()));

        // CARGA DE USERDETAILS PARA JWT (Corrección de tipo)
        UserDetails userDetails = userDetailsService.loadUserByUsername(usuario.getEmail());
        String token = jwtUtils.generateToken(userDetails);
        
        return usuarioMapper.toAuthResponse(usuario, token);
    }

    private void validarUnicidad(RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.email())) {
            throw new BusinessRuleException("El correo electrónico ya se encuentra registrado en Nexus");
        }
        if (usuarioRepository.existsByDni(request.dni())) {
            throw new BusinessRuleException("El DNI introducido ya existe en nuestro sistema");
        }
    }
}
