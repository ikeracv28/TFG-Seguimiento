package com.tfg.api.services.impl;

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
 * Implementación de los servicios de autenticación y seguridad de la aplicación.
 * Esta clase gestiona el registro de usuarios, la validación de credenciales y la emisión de tokens JWT.
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

    @Override
    @Transactional
    public AuthResponse registrar(RegisterRequest request) {
        validarUnicidad(request);

        Usuario usuario = usuarioMapper.registerToEntity(request);
        usuario.setPasswordHash(passwordEncoder.encode(request.password()));

        // Asignación por defecto del rol "ALUMNO" para los nuevos registros.
        Rol rolAlumno = rolRepository.findByNombre("ROLE_ALUMNO")
                .orElseThrow(() -> new RuntimeException("Rol ROLE_ALUMNO no encontrado"));
        
        usuario.setRoles(Collections.singleton(rolAlumno));
        usuario.setActivo(true);

        Usuario usuarioGuardado = usuarioRepository.save(usuario);

        UserDetails userDetails = userDetailsService.loadUserByUsername(usuarioGuardado.getEmail());
        String token = jwtUtils.generateToken(userDetails);

        return usuarioMapper.toAuthResponse(usuarioGuardado, token);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        Usuario usuario = usuarioRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        UserDetails userDetails = userDetailsService.loadUserByUsername(usuario.getEmail());
        String token = jwtUtils.generateToken(userDetails);
        
        return usuarioMapper.toAuthResponse(usuario, token);
    }

    /**
     * Verifica que el email y el DNI proporcionados no existan previamente en el sistema.
     */
    private void validarUnicidad(RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.email())) {
            throw new RuntimeException("El email ya está registrado");
        }
        if (usuarioRepository.existsByDni(request.dni())) {
            throw new RuntimeException("El DNI ya existe");
        }
    }
}
