#!/bin/bash

echo "Testing API Gateway..."
echo "======================"

# Test health endpoint
echo "1. Testing health endpoint:"
curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
echo -e "\n"

# Test user service (should fail if not running)
echo "2. Testing user service proxy:"
curl -s http://localhost:3000/users | jq . 2>/dev/null || curl -s http://localhost:3000/users
echo -e "\n"

# Test product service (should fail if not running)  
echo "3. Testing product service proxy:"
curl -s http://localhost:3000/products | jq . 2>/dev/null || curl -s http://localhost:3000/products
echo -e "\n"

# Test root endpoint
echo "4. Testing root endpoint:"
curl -s http://localhost:3000/
echo -e "\n"

echo "Test completed!"
echo ""
echo "To see working proxies, start the microservices:"
echo "  Terminal 1: cd user-service && PORT=3001 npm run start:dev"
echo "  Terminal 2: cd product-service && PORT=3002 npm run start:dev"
echo ""
echo "Then test again:"
echo "  curl http://localhost:3000/users"
echo "  curl http://localhost:3000/products"
