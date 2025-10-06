package com.shoplite.orders.events;

public record OrderRejected(String reason) implements OrderEvent {
}
