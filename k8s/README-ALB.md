# AWS ALB Ingress Controller Setup

Hướng dẫn triển khai API Gateway với AWS Application Load Balancer (ALB) Ingress Controller trên EKS.

## 📋 Prerequisites

1. **EKS Cluster** đã được tạo
2. **kubectl** đã cài đặt và config
3. **AWS CLI** đã cài đặt và config
4. **eksctl** đã cài đặt (cho setup IAM)
5. **Helm** đã cài đặt (cho install ALB Controller)

## 🚀 Setup Steps

### 1. Setup AWS ALB Controller

```bash
# Chạy script setup tự động
chmod +x k8s/aws-alb-controller-setup.sh
./k8s/aws-alb-controller-setup.sh
```

### 2. Build và Push Docker Images

```bash
# Build images
cd api-gateway && docker build -t your-ecr-repo/api-gateway:latest .
cd ../user-service && docker build -t your-ecr-repo/user-service:latest .
cd ../product-service && docker build -t your-ecr-repo/product-service:latest .

# Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-account-id.dkr.ecr.us-east-1.amazonaws.com
docker push your-ecr-repo/api-gateway:latest
docker push your-ecr-repo/user-service:latest
docker push your-ecr-repo/product-service:latest
```

### 3. Update Kubernetes Manifests

Cập nhật image URLs trong các file deployment:

```yaml
# Trong user-service-deployment.yaml, product-service-deployment.yaml, api-service-deployment.yaml
image: your-account-id.dkr.ecr.us-east-1.amazonaws.com/your-ecr-repo/service-name:latest
```

### 4. Deploy Application

```bash
# Deploy với ALB Ingress
chmod +x k8s/deploy-alb.sh
./k8s/deploy-alb.sh
```

## 🔧 Configuration

### ALB Ingress Annotations

| Annotation | Description | Example |
|------------|-------------|---------|
| `alb.ingress.kubernetes.io/scheme` | Load balancer scheme | `internet-facing` |
| `alb.ingress.kubernetes.io/target-type` | Target type | `ip` |
| `alb.ingress.kubernetes.io/listen-ports` | Ports to listen on | `[{"HTTP": 80}]` |
| `alb.ingress.kubernetes.io/ssl-redirect` | SSL redirect port | `443` |
| `alb.ingress.kubernetes.io/certificate-arn` | SSL certificate ARN | `arn:aws:acm:...` |
| `alb.ingress.kubernetes.io/healthcheck-path` | Health check path | `/health` |
| `alb.ingress.kubernetes.io/security-groups` | Security groups | `sg-xxxxxxxxx` |
| `alb.ingress.kubernetes.io/subnets` | Subnet IDs | `subnet-xxx,subnet-yyy` |

### Production Configuration

Để production, cập nhật `alb-ingress.yaml`:

```yaml
annotations:
  alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID
  alb.ingress.kubernetes.io/ssl-redirect: '443'
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  alb.ingress.kubernetes.io/security-groups: sg-xxxxxxxxx
  alb.ingress.kubernetes.io/subnets: subnet-xxxxxxxxx,subnet-yyyyyyyyy
```

## 🔍 Monitoring

### Check ALB Controller Status

```bash
# Check controller pods
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress status
kubectl get ingress -n api-gateway
kubectl describe ingress api-gateway-ingress-simple -n api-gateway
```

### Check ALB in AWS Console

1. Mở AWS Console → EC2 → Load Balancers
2. Tìm ALB được tạo tự động
3. Kiểm tra Target Groups và Health Checks

## 🧪 Testing

### Test Endpoints

```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress api-gateway-ingress-simple -n api-gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test endpoints
curl http://$ALB_URL/health
curl http://$ALB_URL/users
curl http://$ALB_URL/products
```

### Load Testing

```bash
# Install hey tool
go install github.com/rakyll/hey@latest

# Load test
hey -n 1000 -c 10 http://$ALB_URL/health
```

## 🔒 Security

### Network Security

1. **Security Groups**: Cấu hình security groups cho ALB
2. **VPC**: Đảm bảo subnets được tag đúng cho ALB
3. **IAM**: Kiểm tra IAM roles và policies

### SSL/TLS

1. **Certificate**: Tạo certificate trong AWS Certificate Manager
2. **HTTPS**: Cấu hình SSL redirect
3. **WAF**: Thêm AWS WAF nếu cần

## 📊 Cost Optimization

### ALB Cost Optimization

1. **Idle Timeout**: Tăng idle timeout để giảm connection overhead
2. **Target Groups**: Sử dụng IP targets thay vì instance targets
3. **Health Checks**: Tối ưu health check intervals

### Resource Optimization

```yaml
# Trong deployment manifests
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## 🚨 Troubleshooting

### Common Issues

1. **ALB không được tạo**:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. **Health checks fail**:
   ```bash
   kubectl describe ingress -n api-gateway
   kubectl get endpoints -n api-gateway
   ```

3. **SSL certificate issues**:
   ```bash
   aws acm list-certificates
   kubectl describe ingress -n api-gateway
   ```

### Debug Commands

```bash
# Check ALB Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f

# Check ingress events
kubectl describe ingress api-gateway-ingress-simple -n api-gateway

# Check service endpoints
kubectl get endpoints -n api-gateway

# Check pod logs
kubectl logs -n api-gateway deployment/api-gateway
```

## 📚 References

- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [ALB Ingress Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
