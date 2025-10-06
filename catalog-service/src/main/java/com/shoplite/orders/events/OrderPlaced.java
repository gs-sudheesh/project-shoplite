package com.shoplite.orders.events;

public record OrderPlaced(String orderId, String productId, int quantity) {
}
