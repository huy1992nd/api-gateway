# API Gateway với Microservices

Dự án này bao gồm một API Gateway và hai microservices (user-service, product-service) được triển khai với Kubernetes và Istio.

## Cấu trúc dự án

```
api-gateway/
├── api-gateway/          # API Gateway service
├── user-service/         # User microservice  
├── product-service/      # Product microservice
├── k8s/                 # Kubernetes manifests
└── start-dev.sh         # Script chạy development
```

## Cách hoạt động

API Gateway hoạt động như một reverse proxy, route các request theo path:

- `/users/*` → `user-service:3000`
- `/products/*` → `product-service:3000`
- `/health` → Health check của gateway

## Chạy local development

### Cách 1: Sử dụng script tự động
```bash
./start-dev.sh
```

### Cách 2: Chạy thủ công

1. **Cài đặt dependencies:**
```bash
cd api-gateway && npm install
cd ../user-service && npm install  
cd ../product-service && npm install
```

2. **Chạy user-service:**
```bash
cd user-service
PORT=3001 npm run start:dev
```

3. **Chạy product-service:**
```bash
cd product-service  
PORT=3002 npm run start:dev
```

4. **Chạy API Gateway:**
```bash
cd api-gateway
USER_SERVICE_URL=http://localhost:3001 \
PRODUCT_SERVICE_URL=http://localhost:3002 \
npm run start:dev
```

## Test endpoints

```bash
# Health check
curl http://localhost:3000/health

# User service (proxied)
curl http://localhost:3000/users

# Product service (proxied)  
curl http://localhost:3000/products
```

## Triển khai Kubernetes

### 1. Build Docker images
```bash
# Build user-service
cd user-service
docker build -t user-service:latest .

# Build product-service  
cd ../product-service
docker build -t product-service:latest .

# Build api-gateway
cd ../api-gateway
docker build -t api-gateway:latest .
```

### 2. Deploy lên Kubernetes
```bash
kubectl apply -f k8s/
```

### 3. Kiểm tra deployment
```bash
kubectl get pods
kubectl get services
```

## Environment Variables

### API Gateway
- `PORT`: Port để lắng nghe (default: 3000)
- `USER_SERVICE_URL`: URL của user service (default: http://user-service:3000)
- `PRODUCT_SERVICE_URL`: URL của product service (default: http://product-service:3000)

### User Service & Product Service
- `PORT`: Port để lắng nghe (default: 3000)

## Troubleshooting

### Service không khả dụng
- Kiểm tra logs: `kubectl logs <pod-name>`
- Kiểm tra service endpoints: `kubectl get endpoints`
- Kiểm tra Istio VirtualService: `kubectl get virtualservice`

### Local development issues
- Đảm bảo tất cả services đang chạy trên đúng ports
- Kiểm tra environment variables đã set đúng
- Restart gateway nếu thay đổi service URLs
