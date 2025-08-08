#!/bin/bash

echo "Starting API Gateway with microservices..."

# Start user service on port 3001
echo "Starting user-service on port 3001..."
cd user-service && PORT=3001 npm run start:dev &
USER_PID=$!

# Start product service on port 3002  
echo "Starting product-service on port 3002..."
cd ../product-service && PORT=3002 npm run start:dev &
PRODUCT_PID=$!

# Wait a bit for services to start
sleep 5

# Start API gateway on port 3000
echo "Starting api-gateway on port 3000..."
cd ../api-gateway && \
USER_SERVICE_URL=http://localhost:3001 \
PRODUCT_SERVICE_URL=http://localhost:3002 \
npm run start:dev &
GATEWAY_PID=$!

echo "All services started!"
echo "API Gateway: http://localhost:3000"
echo "User Service: http://localhost:3001"
echo "Product Service: http://localhost:3002"
echo ""
echo "Test endpoints:"
echo "  GET http://localhost:3000/users     -> proxies to user-service"
echo "  GET http://localhost:3000/products  -> proxies to product-service"
echo "  GET http://localhost:3000/health    -> gateway health check"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for user interrupt
wait

# Cleanup on exit
echo "Stopping all services..."
kill $USER_PID $PRODUCT_PID $GATEWAY_PID 2>/dev/null
echo "All services stopped."
