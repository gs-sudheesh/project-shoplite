package com.shoplite.orders.events;

// Java 17 sealed interfaces for safe polymorphism
public sealed interface OrderEvent permits OrderPlaced, OrderRejected {
}
