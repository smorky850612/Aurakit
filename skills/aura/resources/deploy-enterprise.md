# AuraKit — Enterprise Deploy (K8s · Terraform · CI/CD)

> Scout가 Enterprise 복잡도 감지 시 자동 로딩.
> `/aura deploy:` + Enterprise 프로젝트에서 사용.
> Starter/Dynamic → `deploy-pipeline.md` 참조.

---

## 레벨 감지

```bash
# Enterprise 조건 (Scout 기준)
if [ -d "k8s" ] || [ -d "kubernetes" ] || \
   ls Dockerfile.* 2>/dev/null | wc -l | awk '$1>2{exit 0};{exit 1}' || \
   [ -d "terraform" ] || [ -f "docker-compose.prod.yml" ]; then
  echo "Enterprise 감지 → deploy-enterprise.md 로딩"
fi
```

---

## 1. Kubernetes 매니페스트

### Deployment (health check + HPA)

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  labels:
    app: ${APP_NAME}
    version: ${VERSION}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
        - name: ${APP_NAME}
          image: ${ECR_REGISTRY}/${APP_NAME}:${VERSION}
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: ${APP_NAME}-secrets
                  key: database-url
          resources:
            requests:
              cpu: 250m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1Gi
          readinessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /api/health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
```

### HPA (Horizontal Pod Autoscaler)

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${APP_NAME}-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${APP_NAME}
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### Service + Ingress

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-svc
spec:
  selector:
    app: ${APP_NAME}
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
---
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APP_NAME}-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - ${DOMAIN}
      secretName: ${APP_NAME}-tls
  rules:
    - host: ${DOMAIN}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ${APP_NAME}-svc
                port:
                  number: 80
```

---

## 2. Terraform (AWS ECS + RDS)

```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "${TF_STATE_BUCKET}"
    key    = "${APP_NAME}/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# RDS (Aurora Serverless v2)
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.app_name}-${var.environment}"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  serverlessv2_scaling_configuration {
    max_capacity = 16
    min_capacity = 0.5
  }
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name

  tags = local.common_tags
}

locals {
  common_tags = {
    App         = var.app_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

```hcl
# terraform/variables.tf
variable "app_name"    { type = string }
variable "environment" { type = string }
variable "aws_region"  { default = "ap-northeast-2" }
variable "db_name"     { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string; sensitive = true }
```

---

## 3. GitHub Actions CI/CD (멀티 스테이지)

```yaml
# .github/workflows/deploy.yml
name: Deploy Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: ap-northeast-2
  ECR_REGISTRY: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-northeast-2.amazonaws.com

jobs:
  # Stage 1: 코드 품질
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npx tsc --noEmit
      - run: npm audit --audit-level=high

  # Stage 2: 테스트
  test:
    needs: quality
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/

  # Stage 3: 빌드 + ECR 푸시
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    outputs:
      image-tag: ${{ steps.meta.outputs.version }}
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      - id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.ECR_REGISTRY }}/${{ github.event.repository.name }}
          tags: type=sha,format=short
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # Stage 4: 스테이징 배포
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: |
          aws ecs update-service \
            --cluster ${APP_NAME}-staging \
            --service ${APP_NAME} \
            --force-new-deployment \
            --region ${{ env.AWS_REGION }}

  # Stage 5: 프로덕션 배포 (승인 필요)
  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://${{ vars.DOMAIN }}
    steps:
      - run: |
          aws ecs update-service \
            --cluster ${APP_NAME}-prod \
            --service ${APP_NAME} \
            --force-new-deployment \
            --region ${{ env.AWS_REGION }}
```

---

## 4. ArgoCD GitOps (선택)

```yaml
# k8s/argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${ORG}/${APP_NAME}
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: ${APP_NAME}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

## Enterprise Deploy 체크리스트

```
사전 확인:
  [ ] kubectl context 확인: kubectl config current-context
  [ ] Terraform state backend 설정
  [ ] ECR 리포지토리 생성
  [ ] Secrets Manager에 DB 자격증명 저장
  [ ] VPC/서브넷/보안그룹 설계 완료

배포 순서:
  1. terraform apply (인프라)
  2. kubectl apply -f k8s/ (앱)
  3. GitHub Actions 파이프라인 실행
  4. 헬스체크 확인: kubectl get pods -n ${APP_NAME}
  5. Ingress 확인: kubectl get ingress -n ${APP_NAME}

롤백:
  # K8s 롤백
  kubectl rollout undo deployment/${APP_NAME} -n ${APP_NAME}
  # Terraform 롤백
  terraform apply -target=aws_ecs_service.main -var="image_tag=PREVIOUS_TAG"
```

---

*AuraKit Enterprise Deploy — K8s · Terraform · GitHub Actions 5-Stage · ArgoCD GitOps*
