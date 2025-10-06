package com.shoplite.orders.api;

import com.shoplite.orders.api.dto.PlaceOrderRequest;
import com.shoplite.orders.events.OrderEvent;
import com.shoplite.orders.events.OrderPlaced;
import com.shoplite.orders.events.OrderRejected;
import com.shoplite.orders.service.OrderService;
import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private static final Logger log = LoggerFactory.getLogger(OrderController.class);
    private final OrderService orderService;
    private final Tracer tracer;

    public OrderController(OrderService orderService, Tracer tracer) {
        this.orderService = orderService;
        this.tracer = tracer;
    }

    @PostMapping
    public ResponseEntity<OrderEvent> place(@RequestBody PlaceOrderRequest placeOrderRequest) {
        Span span = tracer.nextSpan().name("place-order")
                .tag("product.id", placeOrderRequest.productId().toString())
                .tag("quantity", String.valueOf(placeOrderRequest.quantity())).start();

        try (Tracer.SpanInScope ws = tracer.withSpan(span)) {
            log.info("Received request to place order for product ID: {} with quantity: {}",
                    placeOrderRequest.productId(), placeOrderRequest.quantity());

            // Add log as span event
            span.event("Order request received")
                    .tag("product.id", placeOrderRequest.productId().toString())
                    .tag("quantity", String.valueOf(placeOrderRequest.quantity()));

            var event = orderService.place(placeOrderRequest);
            return switch (event) {
                case OrderPlaced orderPlaced -> {
                    log.info("Order placed successfully with ID: {}", orderPlaced.orderId());
                    span.event("Order placed successfully")
                            .tag("order.id", orderPlaced.orderId().toString())
                            .tag("status", "SUCCESS");
                    yield ResponseEntity.ok(orderPlaced);
                }
                case OrderRejected orderRejected -> {
                    log.warn("Order rejected for product ID: {} due to: {}",
                            placeOrderRequest.productId(), orderRejected.reason());
                    span.event("Order rejected").tag("reason", orderRejected.reason()).tag("status",
                            "REJECTED");
                    yield ResponseEntity.badRequest().body(orderRejected);
                }
            };
        } finally {
            span.end();
        }
    }
}
