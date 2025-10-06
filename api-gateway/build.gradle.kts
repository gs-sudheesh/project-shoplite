plugins {
    id("org.springframework.boot") version "3.3.2"
    id("io.spring.dependency-management")
    java
}

java { toolchain { languageVersion.set(JavaLanguageVersion.of(21)) } }

dependencies {
    implementation("org.springframework.cloud:spring-cloud-starter-gateway")
    implementation("org.springframework.cloud:spring-cloud-starter-netflix-eureka-client")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-oauth2-resource-server")
    
    // Micrometer Tracing + Brave bridge
    implementation("io.micrometer:micrometer-tracing-bridge-brave:1.3.2")
    
    // Zipkin Brave reporter compatible with Spring Boot 3.3.x
    implementation("io.zipkin.reporter2:zipkin-reporter-brave:3.5.1")
    
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.cloud:spring-cloud-dependencies:2023.0.1")
    }
}
