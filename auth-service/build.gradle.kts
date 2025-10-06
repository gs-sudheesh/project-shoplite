plugins {
    java
    id("org.springframework.boot") version "3.3.2"
    id("io.spring.dependency-management")
}

group = "com.shoplite"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    
    // OAuth2 JWT Support
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server")
    
    // Auth0/Okta Integration
    implementation("com.auth0:auth0-spring-security-api:1.4.1")
    implementation("com.auth0:java-jwt:4.4.0")
    
    // Database
    implementation("org.postgresql:postgresql")
    
    // Service Discovery
    implementation("org.springframework.cloud:spring-cloud-starter-netflix-eureka-client")
    
    // Micrometer Tracing + Brave bridge
    implementation("io.micrometer:micrometer-tracing-bridge-brave:1.3.2")
    
    // Zipkin Brave reporter compatible with Spring Boot 3.3.x
    implementation("io.zipkin.reporter2:zipkin-reporter-brave:3.5.1")
    
    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:2023.0.1")
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
}
