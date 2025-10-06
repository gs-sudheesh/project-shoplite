package com.shoplite.orders.api.dto;

// Java 16+ records (highlight vs POJOs)
public record PlaceOrderRequest(String productId, int quantity) {
}
