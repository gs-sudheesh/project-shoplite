package com.shoplite.catalog.listeners;

import com.shoplite.catalog.repo.ProductRepository;
import com.shoplite.orders.events.OrderPlaced;
import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Headers;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class OrderPlacedListener {

        private static final Logger log = LoggerFactory.getLogger(OrderPlacedListener.class);

        private final ProductRepository productRepository;
        private final Tracer tracer;

        public OrderPlacedListener(ProductRepository productRepository, Tracer tracer) {
                this.productRepository = productRepository;
                this.tracer = tracer;
        }

        @KafkaListener(topics = "orders.events", groupId = "catalog-service",
                        containerFactory = "kafkaListenerContainerFactory")
        @Transactional
        public void listen(OrderPlaced orderPlaced, @Header(KafkaHeaders.RECEIVED_KEY) String key,
                        @Headers Map<String, Object> headers) {

                Span currentSpan = tracer.nextSpan().name("catalog.order-processing")
                                .tag("order.id", orderPlaced.orderId())
                                .tag("product.id", orderPlaced.productId())
                                .tag("order.quantity", String.valueOf(orderPlaced.quantity()))
                                .start();

                try (Tracer.SpanInScope ws = tracer.withSpan(currentSpan)) {
                        // Log trace information
                        String traceId = currentSpan.context().traceId();
                        String spanId = currentSpan.context().spanId();

                        log.info("Processing OrderPlaced event - TraceId: {}, SpanId: {}, Order: {}",
                                        traceId, spanId, orderPlaced);
                        log.debug("Kafka Headers: {}", headers);

                        productRepository.findById(orderPlaced.productId())
                                        .ifPresentOrElse(product -> {
                                                int originalStock = product.getStock();
                                                int updatedStock = Math.max(0, originalStock
                                                                - orderPlaced.quantity());
                                                product.setStock(updatedStock);
                                                productRepository.save(product);

                                                currentSpan.tag("stock.original",
                                                                String.valueOf(originalStock))
                                                                .tag("stock.updated", String
                                                                                .valueOf(updatedStock))
                                                                .tag("stock.change", String.valueOf(
                                                                                originalStock - updatedStock));

                                                log.info("Stock updated for product {} - Original: {}, Updated: {}, TraceId: {}",
                                                                product.getId(), originalStock,
                                                                updatedStock, traceId);
                                        }, () -> {
                                                currentSpan.tag("error", "product.not.found");
                                                log.warn("Product {} not found for order {} - TraceId: {}",
                                                                orderPlaced.productId(),
                                                                orderPlaced.orderId(), traceId);
                                        });

                } catch (Exception e) {
                        currentSpan.tag("error", e.getClass().getSimpleName()).tag("error.message",
                                        e.getMessage());
                        log.error("Error processing OrderPlaced event: {} - TraceId: {}",
                                        orderPlaced, currentSpan.context().traceId(), e);
                        throw e;
                } finally {
                        currentSpan.end();
                }
        }
}
