package com.shoplite.orders.service;

import com.shoplite.orders.api.dto.PlaceOrderRequest;
import com.shoplite.orders.events.OrderPlaced;
import com.shoplite.orders.events.OrderRejected;
import com.shoplite.orders.events.OrderEvent;
import com.shoplite.orders.domain.Order;
import com.shoplite.orders.repo.OrderRepository;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

    private static final Logger LOG = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;
    private final KafkaTemplate<String, OrderPlaced> kafkaTemplate;

    public OrderService(OrderRepository orderRepository,
            KafkaTemplate<String, OrderPlaced> kafkaTemplate) {
        this.orderRepository = orderRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    public OrderEvent place(PlaceOrderRequest placeOrderRequest) {
        if (placeOrderRequest.quantity() <= 0) {
            var orderRejected = new OrderRejected("Quantity must be > 0");
            LOG.warn(toLogLine(orderRejected));
            return orderRejected;
        }
        var order = new Order(); // Java 10 var
        order.setProductId(placeOrderRequest.productId());
        order.setQuantity(placeOrderRequest.quantity());
        orderRepository.save(order);

        LOG.debug("Order to be placed: {}", order);

        var createOrderEvent =
                new OrderPlaced(order.getId(), order.getProductId(), order.getQuantity());
        kafkaTemplate.send("orders.events", order.getId(), createOrderEvent);
        LOG.info(toLogLine(createOrderEvent));
        return createOrderEvent;
    }

    // Example of pattern matching switch on sealed hierarchy
    public String toLogLine(OrderEvent orderEvent) {
        return switch (orderEvent) {
            case OrderPlaced orderPlaced -> "OrderPlaced: %s".formatted(orderPlaced.orderId());
            case OrderRejected orderRejected -> "OrderRejected: %s"
                    .formatted(orderRejected.reason());
        };
    }

    public String sampleSqlTextBlock() {
        return """
                SELECT id, product_id, quantity, created_at
                FROM orders
                WHERE quantity >= 1
                """;
    }
}
