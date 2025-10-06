package com.shoplite.orders;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;

/**
 * Order Service entrypoint.
 *
 * Registers with Eureka and runs as an OAuth2 resource server (see SecurityConfig) validating Auth0
 * JWTs for API access.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class OrderServiceApplication {
  public static void main(String[] args) {
    SpringApplication.run(OrderServiceApplication.class, args);
  }

  // Java 21: virtual threads to keep MVC imperative but scale IO
  /**
   * ExecutorService virtualThreadExecutor(): This method returns a new ExecutorService.
   *
   * <p>
   * Executors.newVirtualThreadPerTaskExecutor(): This is the factory method from the
   * java.util.concurrent package (introduced in Java 21) that creates an ExecutorService that uses
   * virtual threads. Each task submitted to this executor will run on its own dedicated virtual
   * thread.
   *
   * <p>
   * When you add this bean to your Spring application, Spring Boot's auto-configuration will detect
   * it and use it as the TaskExecutor for its default ThreadPoolTaskExecutor. This effectively
   * replaces the traditional fixed-size thread pool for handling incoming web requests with a
   * virtual-thread-based approach. The result is that you can handle thousands or even millions of
   * concurrent connections without the overhead of traditional threads, significantly improving the
   * scalability of your imperative REST APIs
   */
  @Bean
  ExecutorService virtualThreadExecutor() {
    return Executors.newVirtualThreadPerTaskExecutor();
  }
}