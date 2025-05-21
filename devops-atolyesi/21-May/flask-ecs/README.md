## ⚙️ Flask App for AWS ECS Deployment

Bu proje, bir Flask uygulamasının AWS ECS (Fargate) üzerinde çalıştırılmasını kolaylaştıran shell script'ler içerir. Script'ler iki farklı yapılandırma seçeneği sunar:

### 1. `ecs-2-create.sh` ve `ecs-2-cleanup.sh`

- Yeni bir **ECS Cluster (Fargate)**, **Load Balancer** ve **VPC** oluşturur.
- **Uyarı:** AWS Fargate ve Load Balancer kullanımı ek maliyet oluşturur. Test işlemleriniz tamamlandığında kaynakları silmeyi unutmayın.
- `ecs-2-cleanup.sh` script'i bağımlılıklar nedeniyle VPC'yi silemez. Bu nedenle VPC'yi manuel olarak **AWS Console** üzerinden silmeniz gerekir.

### 2. `ecs-setup.sh` ve `ecs-cleanup.sh`

- Mevcut **default VPC** içinde **Load Balancer oluşturmadan** ECS Cluster (Fargate), Service ve Task oluşturur.
- Yalnızca AWS Fargate kullanımından dolayı ücret alınır.

> ⚠️ **Not:** Bu script'ler yalnızca test ve geliştirme ortamları için önerilir. Prod ortamında kullanılması tavsiye edilmez.
