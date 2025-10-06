package com.shoplite.catalog.repo;

import com.shoplite.catalog.domain.Product;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ProductRepository extends MongoRepository<Product, String> {
}
