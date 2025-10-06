plugins {
    id("org.springframework.boot") version "3.3.2" apply false
    id("io.spring.dependency-management") version "1.1.5" apply false
    kotlin("jvm") version "2.0.0" apply false // not used now, but handy later
}

subprojects {
    repositories { mavenCentral() }
}
