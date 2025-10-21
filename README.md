# Shoplite — Microservices Reference

## 🏗️ **Architecture Overview**

Shoplite has been successfully transformed from a distributed monolith to a **proper microservices architecture** implementing core microservices principles. This project demonstrates true microservices patterns without the complexity of production-level resilience features.

### **Services**

1. **Eureka Server** (Port 8761)
   - Service discovery and registration
   - Central registry for all microservices

2. **API Gateway** (Port 8080)
   - Single entry point for all client requests
   - Routes requests to appropriate services via Eureka
   - Load balancing using service names
   - WebFlux security validates Auth0 JWTs and enforces scopes

3. **Order Service** (Port 8081)
   - Handles order creation and management
   - PostgreSQL database
   - Publishes events to Kafka

4. **Catalog Service** (Port 8082)
   - Manages product catalog
   - MongoDB database
   - Consumes order events from Kafka
   - JWT-protected APIs (resource server)

5. **Auth Service** (Port 8083)
   - User registration API and JWT validation (resource server)
   - Auth0 is the IdP; this service does not mint tokens
   - PostgreSQL database (`shoplite_auth` on 5433)

### **Infrastructure**

- **Kafka**: Event streaming platform
- **PostgreSQL**: Order data persistence
- **MongoDB**: Product catalog persistence
- **Jaeger**: Distributed tracing (OpenTelemetry compatible)
- **Kafka UI**: Kafka management interface

## ⚙️ **Configuration Management**

The project uses **environment variables** for all configuration, making it production-ready and secure:

### **Environment Variable Strategy**
- **No Hardcoded Values**: All URLs, ports, and credentials externalized
- **Service-Specific Config**: Each service has its own environment variables
- **Security-First**: Sensitive data (passwords, API keys) kept out of code
- **Environment Flexibility**: Easy to configure for dev/staging/production

### **Available Scripts**
```bash
# Start all services with proper environment variables
./start-all-services.sh

# Start individual services
./start-eureka.sh
./start-order-service.sh
./start-catalog-service.sh
./start-auth-service.sh
./start-api-gateway.sh

# Check service status
./check-services.sh

# Stop all services
./stop-all-services.sh
```

### **Configuration Files**
- `ENVIRONMENT_VARIABLES.md`: Complete documentation of all environment variables
- `application.yml`: Uses `${VAR_NAME}` syntax for environment variable substitution
- Service-specific environment variables for database connections, Auth0, Kafka, etc.

## 🚀 **Core Microservices Principles Implemented**

This architecture demonstrates **all essential microservices patterns**:

### ✅ **Service Independence & Autonomy**
- **No Shared Dependencies**: Removed `shoplite-common` library completely
- **Independent Event Definitions**: Each service defines its own events
- **Separate Data Ownership**: PostgreSQL for orders, MongoDB for catalog
- **Independent Deployment**: Each service can be deployed separately
- **Technology Diversity**: Services can use different tech stacks

### ✅ **Service Discovery & Registration**
- **Dynamic Discovery**: Eureka server for automatic service registration
- **Load Balancing**: Services discovered by name, not hardcoded URLs
- **Health Monitoring**: Automatic service health checks
- **Scalability Ready**: Can run multiple instances of each service

### ✅ **API Gateway Pattern**
- **Single Entry Point**: All client requests go through gateway (Port 8080)
- **Service Abstraction**: Clients don't know individual service locations
- **Centralized Routing**: Routes automatically configured via Eureka
- **Cross-Cutting Concerns**: Central auth (JWT validation, scopes) and CORS

### ✅ **Event-Driven Architecture**
- **Asynchronous Communication**: Kafka for inter-service messaging
- **Loose Coupling**: Services communicate via events, not direct calls
- **Eventual Consistency**: Proper handling of distributed data updates
- **Scalable Messaging**: Ready for high-throughput event processing

### ✅ **Domain-Driven Design**
- **Clear Boundaries**: Order and Catalog domains are separate
- **Business Logic Encapsulation**: Each service owns its business rules
- **Data Consistency**: Each service manages its own data integrity

## 🔄 **Request Flow**

```
Frontend (5173) → API Gateway (8080) → Eureka (8761) → Target Service
    ↓
API Gateway (Port 8080)
    ↓
Eureka Server (Port 8761) - Service Discovery
    ↓
Order Service (Port 8081) or Catalog Service (Port 8082)
```

## 📋 **Running the Microservices**

### **Prerequisites**
- Java 21
- Docker & Docker Compose
- Node.js & npm

### **1. Verify Build**
```bash
./gradlew clean build
# Should complete successfully with all services
```

### **2. Start Infrastructure (Docker)**
```bash
docker-compose up -d
# Starts: Kafka, Zookeeper, PostgreSQL, MongoDB, Jaeger, Kafka UI
# Note: Microservices run locally with Gradle, not in Docker
```

### **3. Start Microservices Locally**

#### **Option A: Start All Services at Once (Recommended)**
```bash
# Start all services with proper environment variables and startup order
./start-all-services.sh

# Check service status
./check-services.sh

# Stop all services when done
./stop-all-services.sh
```

#### **Option B: Start Services Individually**
```bash
# Terminal 1: Service Discovery
export SERVER_PORT=8761
export JAEGER_ENDPOINT=http://localhost:9411/api/v2/spans
./gradlew :eureka-server:bootRun

# Terminal 2: Order Service (wait for Eureka to start)
export AUTH0_ISSUER_URI=https://your-domain.auth0.com/
export AUTH0_AUDIENCE=https://api.shoplite.com
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=ordersdb
export DB_USERNAME=orders
export DB_PASSWORD=orders
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export EUREKA_DEFAULT_ZONE=http://localhost:8761/eureka/
export JAEGER_ENDPOINT=http://localhost:9411/api/v2/spans
export SERVER_PORT=8081
./gradlew :order-service:bootRun

# Terminal 3: Catalog Service
export AUTH0_ISSUER_URI=https://your-domain.auth0.com/
export AUTH0_AUDIENCE=https://api.shoplite.com
export MONGO_HOST=localhost
export MONGO_PORT=27017
export MONGO_DATABASE=catalogdb
export MONGO_USERNAME=catalog
export MONGO_PASSWORD=catalog
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export EUREKA_DEFAULT_ZONE=http://localhost:8761/eureka/
export JAEGER_ENDPOINT=http://localhost:9411/api/v2/spans
export SERVER_PORT=8082
./gradlew :catalog-service:bootRun

# Terminal 4: Auth Service
export AUTH0_ISSUER_URI=https://your-domain.auth0.com/
export AUTH0_AUDIENCE=https://api.shoplite.com
export DB_HOST=localhost
export DB_PORT=5433
export DB_NAME=shoplite_auth
export DB_USERNAME=shoplite
export DB_PASSWORD=shoplite
export EUREKA_DEFAULT_ZONE=http://localhost:8761/eureka/
export JAEGER_ENDPOINT=http://localhost:9411/api/v2/spans
export SERVER_PORT=8083
./gradlew :auth-service:bootRun

# Terminal 5: API Gateway
export AUTH0_ISSUER_URI=https://your-domain.auth0.com/
export AUTH0_AUDIENCE=https://api.shoplite.com
export CORS_ALLOWED_ORIGINS=http://localhost:5173
export EUREKA_DEFAULT_ZONE=http://localhost:8761/eureka/
export JAEGER_ENDPOINT=http://localhost:9411/api/v2/spans
export SERVER_PORT=8080
./gradlew :api-gateway:bootRun

# Terminal 6: Frontend
cd frontend && npm run dev
```

### **4. Verify Services Registration**
Visit http://localhost:8761 to see all services registered with Eureka.

### **5. Test the Complete Flow**
1. **Create a Product**: Visit http://localhost:5173/create-product
2. **View Products**: Visit http://localhost:5173/products  
3. **Place an Order**: Visit http://localhost:5173/create-order
4. **Verify Stock Update**: Check MongoDB for stock changes
5. **Check Distributed Tracing**: Visit http://localhost:16686 (Jaeger UI)

### **6. Verify Service Communication**
- **Frontend → API Gateway**: http://localhost:8080 (with CORS support)
- **API Gateway → Services**: Automatic routing via Eureka
- **Service-to-Service**: Kafka events for async communication
- **Service Discovery**: http://localhost:8761 (Eureka Dashboard)

### **7. Security & CORS**
- Identity Provider: Auth0 (issuer + JWKS)
- Audience: `https://api.shoplite.com`
- Scopes: `products:read`, `products:write`, `orders:write`
- Gateway scope rules:
  - GET `/api/products/**` → `products:read`
  - POST/PUT/DELETE `/api/products/**` → `products:write`
  - POST `/api/orders/**` → `orders:write`
- CORS (gateway): allows `http://localhost:5173`

### **Frontend environment (.env.local)**
Create `frontend/.env.local` with the following keys (do not commit secrets):

```
# Auth0 tenant domain (without protocol)
VITE_AUTH0_DOMAIN=your-tenant.auth0.com

# SPA application Client ID (no secret needed for PKCE)
VITE_AUTH0_CLIENT_ID=your-spa-client-id

# API identifier configured in Auth0 API settings
VITE_AUTH0_AUDIENCE=https://api.shoplite.com
```

Notes:
- The SPA uses PKCE; no client secret is required on the frontend.
- These values are injected at build/dev time by Vite (`import.meta.env`).

## 🌐 **Service URLs**

- **Eureka Dashboard**: http://localhost:8761
- **API Gateway**: http://localhost:8080
- **Order Service**: http://localhost:8081
- **Catalog Service**: http://localhost:8082
- **Auth Service**: http://localhost:8083
- **Frontend**: http://localhost:5173
- **Jaeger UI**: http://localhost:16686
- **Jaeger Collector**: http://localhost:9411
- **Kafka UI**: http://localhost:8085

## 🔍 **Testing the Architecture**

### **Service Discovery Test**
1. Visit http://localhost:8761
2. Verify all services are registered
3. Check health status

### **API Gateway Test**
1. Frontend now routes through http://localhost:8080
2. All API calls go through the gateway
3. Services are discovered automatically

### **Event Flow Test**
1. Create a product via catalog service
2. Place an order via order service
3. Verify stock update via Kafka events

## ✅ **Microservices Architecture Validation**

### **Core Requirements Met:**
- ✅ **Service Independence**: No shared libraries, separate codebases
- ✅ **Service Discovery**: Eureka for dynamic registration
- ✅ **API Gateway**: Centralized routing and service abstraction
- ✅ **Event-Driven**: Asynchronous Kafka messaging
- ✅ **Data Ownership**: Each service owns its database
- ✅ **Domain Boundaries**: Clear separation of business logic

### **Architecture Maturity Level:**
```
🏗️ Core Microservices Architecture: ✅ COMPLETE & RUNNING
🛡️ Resilience Patterns: 🟡 BASIC (Can be enhanced)
🔐 Production Features: 🔴 MINIMAL (Security, monitoring)
```

### **Current Status:**
- ✅ **Infrastructure**: Docker containers running (Kafka, MongoDB, PostgreSQL, Jaeger)
- ✅ **Eureka Server**: Running on port 8761
- ✅ **API Gateway**: Running on port 8080
- ✅ **Order Service**: Running on port 8081
- ✅ **Catalog Service**: Running on port 8082
- ✅ **Auth Service**: Running on port 8083
- ✅ **Frontend**: Running on port 5173
- ✅ **Startup Scripts**: Automated service startup/shutdown scripts available

## 🎯 **Optional Enhancements for Production**

*Note: These are enhancements, not requirements for microservices architecture*

### **Phase 1: Resilience Patterns**
- [ ] Circuit breakers (Resilience4j)
- [ ] Retry mechanisms with exponential backoff
- [ ] Bulkhead pattern for resource isolation
- [ ] Timeout configurations

### **Phase 2: Security & Authentication**
- [ ] JWT-based authentication
- [ ] OAuth2/OIDC integration
- [ ] API rate limiting
- [ ] Service-to-service authentication

### **Phase 3: Observability**
- [ ] Prometheus metrics collection
- [ ] Grafana dashboards
- [ ] Centralized logging (ELK stack)
- [x] **Distributed tracing (Jaeger)** - ✅ IMPLEMENTED

### **Phase 4: DevOps & Deployment**
- [ ] Docker containerization
- [ ] Kubernetes orchestration
- [ ] Helm charts for deployment
- [ ] CI/CD pipeline automation

### **Phase 5: Configuration Management**
- [x] **Environment variable externalization** - ✅ IMPLEMENTED
- [x] **Automated startup scripts** - ✅ IMPLEMENTED
- [ ] Secret management integration (AWS Secrets Manager, HashiCorp Vault)
- [ ] Configuration hot-reloading

## 📚 **Learning & Interview Benefits**

### **Key Concepts Demonstrated:**
- **Service Discovery**: Dynamic service registration and discovery with Eureka
- **API Gateway Pattern**: Centralized routing, service abstraction, and cross-cutting concerns
- **Event-Driven Architecture**: Asynchronous communication via Kafka events
- **Service Independence**: No shared dependencies, separate deployment units
- **Data Ownership**: Each service manages its own database
- **Load Balancing**: Automatic service distribution through gateway
- **Domain-Driven Design**: Clear business domain boundaries
- **Configuration Management**: Environment variable externalization for security and flexibility
- **Distributed Tracing**: End-to-end request tracking with Jaeger
- **Automated Operations**: Startup/shutdown scripts for operational efficiency

### **Interview Talking Points:**
1. **"Why remove shared library?"** - Eliminates coupling, enables independent deployment
2. **"How do services communicate?"** - REST via Gateway + Events via Kafka
3. **"What about data consistency?"** - Eventual consistency through event sourcing
4. **"How do you scale?"** - Each service scales independently based on load
5. **"What about service discovery?"** - Eureka provides dynamic registration and discovery
6. **"How do you handle configuration?"** - Environment variables externalized, no hardcoded values
7. **"How do you monitor distributed systems?"** - Jaeger for distributed tracing across services
8. **"How do you manage operations?"** - Automated scripts for startup/shutdown with proper sequencing

### **Microservices vs Monolith Comparison:**
```
Monolith:
├── Single deployment unit
├── Shared database
├── Direct method calls
└── Centralized scaling

Microservices (This Project):
├── Independent deployments ✅
├── Service-owned databases ✅  
├── Network-based communication ✅
└── Service-specific scaling ✅
```

### **Architecture Maturity for Learning:**
- ✅ **Beginner**: Perfect introduction to microservices concepts
- ✅ **Intermediate**: Demonstrates real-world patterns and practices
- ✅ **Advanced**: Ready for production enhancements (security, resilience)


# Trigger CI workflow
