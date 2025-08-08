import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { createProxyMiddleware } from 'http-proxy-middleware';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { 
    bufferLogs: true 
  });
  
  // Enable CORS
  app.enableCors();

  const port = process.env.PORT || 3000;
  const userTarget = process.env.USER_SERVICE_URL || 'http://localhost:3001';
  const productTarget = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002';

  // Proxy middleware for user service
  app.use(
    '/users',
    createProxyMiddleware({
      target: userTarget,
      changeOrigin: true,
      pathRewrite: { '^/users': '/' },
      proxyTimeout: 10000,
      timeout: 10000,
      onError: (err, req, res) => {
        console.error('User service proxy error:', err.message);
        res.status(503).json({ 
          error: 'User service unavailable',
          message: 'The user service is currently unavailable'
        });
      },
    }),
  );

  // Proxy middleware for product service
  app.use(
    '/products',
    createProxyMiddleware({
      target: productTarget,
      changeOrigin: true,
      pathRewrite: { '^/products': '/' },
      proxyTimeout: 10000,
      timeout: 10000,
      onError: (err, req, res) => {
        console.error('Product service proxy error:', err.message);
        res.status(503).json({ 
          error: 'Product service unavailable',
          message: 'The product service is currently unavailable'
        });
      },
    }),
  );

  // Health check endpoint
  app.use('/health', (req, res) => {
    res.status(200).json({ 
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'api-gateway'
    });
  });

  await app.listen(port as number);
  console.log(`API Gateway is running on port ${port}`);
  console.log(`User service target: ${userTarget}`);
  console.log(`Product service target: ${productTarget}`);
}
bootstrap();
