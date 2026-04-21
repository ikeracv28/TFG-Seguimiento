package com.tfg.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

/**
 * Clase principal que arranca la aplicación Spring Boot.
 * La anotación @SpringBootApplication habilita la auto-configuración, 
 * el escaneo de componentes y la configuración de clases.
 */
@SpringBootApplication
@EnableMethodSecurity
public class TfgApiApplication {

    public static void main(String[] args) {
        // Método estándar para iniciar la aplicación.
        SpringApplication.run(TfgApiApplication.class, args);
    }
}
