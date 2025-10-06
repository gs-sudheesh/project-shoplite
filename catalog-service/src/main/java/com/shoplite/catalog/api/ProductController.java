package com.shoplite.catalog.api;

import com.shoplite.catalog.api.dto.ProductDto;
import com.shoplite.catalog.domain.Product;
import com.shoplite.catalog.repo.ProductRepository;
import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    private static final Logger log = LoggerFactory.getLogger(ProductController.class);
    private final ProductRepository productRepository;
    private final Tracer tracer;

    public ProductController(ProductRepository productRepository, Tracer tracer) {
        this.productRepository = productRepository;
        this.tracer = tracer;
    }

    @GetMapping
    public List<ProductDto> fetchAllProducts() {
        Span span = tracer.nextSpan().name("fetch-all-products").start();

        try (Tracer.SpanInScope ws = tracer.withSpan(span)) {
            log.info("Fetching all products");
            span.event("Fetching all products from database");

            List<ProductDto> products = productRepository.findAll().stream()
                    .map(product -> new ProductDto(product.getId(), product.getName(),
                            product.getStock()))
                    .toList();

            span.tag("products.count", String.valueOf(products.size()));
            span.event("Products fetched successfully");
            log.info("Fetched {} products", products.size());

            return products;
        } finally {
            span.end();
        }
    }

    @PostMapping
    public ResponseEntity<ProductDto> createNewProduct(@RequestBody ProductDto productDto) {
        Span span = tracer.nextSpan().name("create-product").tag("product.name", productDto.name())
                .tag("product.stock", String.valueOf(productDto.stock())).start();

        try (Tracer.SpanInScope ws = tracer.withSpan(span)) {
            log.info("Creating new product: {}", productDto.name());
            span.event("Creating new product").tag("product.name", productDto.name())
                    .tag("product.stock", String.valueOf(productDto.stock()));

            var product = new Product(productDto.name(), productDto.stock());
            var savedProduct = productRepository.save(product);

            span.tag("product.id", savedProduct.getId().toString());
            span.event("Product created successfully");
            log.info("Product created with ID: {}", savedProduct.getId());

            return ResponseEntity.ok(new ProductDto(savedProduct.getId(), savedProduct.getName(),
                    savedProduct.getStock()));
        } finally {
            span.end();
        }
    }
}
