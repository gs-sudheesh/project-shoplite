package com.shoplite.auth.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.JwtValidators;

import java.util.Arrays;

/**
 * Auth service security configuration.
 *
 * This service acts as an OAuth2 Resource Server that validates Auth0-issued access tokens using
 * the tenant's issuer and JWKS. Although it exposes auth endpoints (e.g., register/validate), it
 * does not mint tokens itself.
 *
 * Key points: - Stateless sessions; CSRF disabled for APIs; CORS allowed for frontend dev. - JWT
 * validation enforces issuer and required audience (API identifier). - Only /api/auth/** and
 * /actuator/** are public; all other paths require JWT.
 */
@Configuration
@EnableWebSecurity
public class Auth0Config {

        @Value("${auth0.audience}")
        private String audience;

        @Value("${auth0.issuer}")
        private String issuer;

        /**
         * Builds servlet security chain with CORS, stateless session, public endpoints, and
         * resource server JWT validation.
         */
        @Bean
        public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
                http.cors(cors -> cors.configurationSource(corsConfigurationSource()))
                                .csrf(csrf -> csrf.disable())
                                .sessionManagement(sm -> sm.sessionCreationPolicy(
                                                org.springframework.security.config.http.SessionCreationPolicy.STATELESS))
                                .authorizeHttpRequests(authz -> authz
                                                .requestMatchers("/api/auth/**").permitAll()
                                                .requestMatchers("/actuator/**").permitAll()
                                                .anyRequest().authenticated())
                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt.decoder(jwtDecoder())));

                return http.build();
        }

        /**
         * Decoder that fetches JWKS from the Auth0 issuer and validates issuer + audience.
         */
        @Bean
        public JwtDecoder jwtDecoder() {
                NimbusJwtDecoder decoder =
                                (NimbusJwtDecoder) JwtDecoders.fromIssuerLocation(issuer);

                OAuth2TokenValidator<Jwt> withIssuer =
                                JwtValidators.createDefaultWithIssuer(issuer);
                OAuth2TokenValidator<Jwt> audienceValidator =
                                jwt -> jwt.getAudience().contains(audience)
                                                ? OAuth2TokenValidatorResult.success()
                                                : OAuth2TokenValidatorResult.failure(
                                                                new OAuth2Error("invalid_token",
                                                                                "The required audience is missing",
                                                                                null));

                decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(withIssuer,
                                audienceValidator));
                return decoder;
        }

        /**
         * Permissive CORS for local dev frontend (http://localhost:5173).
         */
        @Bean
        public CorsConfigurationSource corsConfigurationSource() {
                CorsConfiguration configuration = new CorsConfiguration();
                configuration.setAllowedOriginPatterns(Arrays.asList("http://localhost:5173"));
                configuration.setAllowedMethods(
                                Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                configuration.setAllowedHeaders(Arrays.asList("*"));
                configuration.setAllowCredentials(true);

                UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
                source.registerCorsConfiguration("/**", configuration);
                return source;
        }
}
