package com.shoplite.catalog;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Catalog Service entrypoint.
 *
 * Registers with Eureka and exposes product APIs protected by Auth0 JWTs (see SecurityConfig for
 * resource server setup).
 */
@SpringBootApplication
@EnableDiscoveryClient
public class CatalogServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(CatalogServiceApplication.class, args);
    }
}