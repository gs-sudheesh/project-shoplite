package com.shoplite.orders.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class Order {
  @Id
  private String id = UUID.randomUUID().toString();

  private String productId;
  private int quantity;
  private Instant createdAt = Instant.now();

  public String getId() {
    return id;
  }

  public String getProductId() {
    return productId;
  }

  public void setProductId(String productId) {
    this.productId = productId;
  }

  public int getQuantity() {
    return quantity;
  }

  public void setQuantity(int quantity) {
    this.quantity = quantity;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  @Override
  public String toString() {
    return "Order{" + "id='" + id + '\'' + ", productId='" + productId + '\'' + ", quantity="
        + quantity + ", createdAt=" + createdAt + '}';
  }

}
