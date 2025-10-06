package com.shoplite.gateway.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.oauth2.server.resource.authentication.ReactiveJwtAuthenticationConverterAdapter;
import org.springframework.security.oauth2.server.resource.web.server.BearerTokenServerAuthenticationEntryPoint;
import org.springframework.security.web.server.authorization.HttpStatusServerAccessDeniedHandler;
import org.springframework.http.HttpStatus;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import reactor.core.publisher.Mono;

/**
 * Gateway security configuration (WebFlux).
 *
 * Why WebFlux: Spring Cloud Gateway is reactive and requires WebFlux security
 * (ServerHttpSecurity/SecurityWebFilterChain).
 *
 * What it does: - Disables CSRF (stateless APIs) and enables CORS (origin set in application.yml).
 * - Validates JWTs from Auth0 (issuer/audience configured in application.yml). - Maps Auth0
 * permissions/scope claims to Spring authorities with prefix "SCOPE_". - Enforces route-level
 * scopes (products:read/products:write/orders:write). - Returns 401 for missing/invalid token and
 * 403 for access denied.
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

        /**
         * Defines the reactive security filter chain for the gateway and applies scope-based
         * authorization rules per route.
         */
        @Bean
        public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
                http.csrf(ServerHttpSecurity.CsrfSpec::disable).cors(Customizer.withDefaults())
                                .authorizeExchange(ex -> ex
                                                .pathMatchers("/api/auth/**", "/actuator/**")
                                                .permitAll().pathMatchers(HttpMethod.OPTIONS, "/**")
                                                .permitAll()
                                                .pathMatchers(HttpMethod.GET, "/api/products/**")
                                                .hasAuthority("SCOPE_products:read")
                                                .pathMatchers(HttpMethod.POST, "/api/products/**")
                                                .hasAuthority("SCOPE_products:write")
                                                .pathMatchers(HttpMethod.PUT, "/api/products/**")
                                                .hasAuthority("SCOPE_products:write")
                                                .pathMatchers(HttpMethod.DELETE, "/api/products/**")
                                                .hasAuthority("SCOPE_products:write")
                                                .pathMatchers(HttpMethod.POST, "/api/orders/**")
                                                .hasAuthority("SCOPE_orders:write").anyExchange()
                                                .authenticated())
                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt.jwtAuthenticationConverter(
                                                                reactiveJwtAuthenticationConverter())))
                                .exceptionHandling(ex -> ex.authenticationEntryPoint(
                                                new BearerTokenServerAuthenticationEntryPoint())
                                                .accessDeniedHandler(
                                                                new HttpStatusServerAccessDeniedHandler(
                                                                                HttpStatus.FORBIDDEN)));
                return http.build();
        }

        /**
         * Converts a JWT into a reactive Authentication by reading authorities from Auth0's
         * permissions claim (and fallback space-delimited scope) and prefixing them with "SCOPE_"
         * to match access rules.
         */
        @Bean
        public Converter<Jwt, Mono<AbstractAuthenticationToken>> reactiveJwtAuthenticationConverter() {
                JwtGrantedAuthoritiesConverter scopes = new JwtGrantedAuthoritiesConverter();
                scopes.setAuthorityPrefix("SCOPE_");
                scopes.setAuthoritiesClaimName("permissions");

                JwtAuthenticationConverter delegate = new JwtAuthenticationConverter();
                delegate.setJwtGrantedAuthoritiesConverter((Jwt jwt) -> {
                        java.util.Collection<GrantedAuthority> authorities =
                                        new java.util.ArrayList<>();
                        authorities.addAll(scopes.convert(jwt));
                        if (jwt.hasClaim("scope")) {
                                String scopeStr = jwt.getClaim("scope");
                                for (String s : scopeStr.split(" ")) {
                                        authorities.add(new SimpleGrantedAuthority("SCOPE_" + s));
                                }
                        }
                        return authorities;
                });
                return new ReactiveJwtAuthenticationConverterAdapter(delegate);
        }
}


