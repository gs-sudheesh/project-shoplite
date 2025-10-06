package com.shoplite.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Auth Service entrypoint.
 *
 * Provides basic user registration and validates access tokens as a resource server; token issuance
 * is delegated to Auth0.
 */
@SpringBootApplication
public class AuthServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}