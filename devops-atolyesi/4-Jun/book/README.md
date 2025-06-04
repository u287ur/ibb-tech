# 📚 Library Management System (Django + React + AWS)

Bu proje, kitap ödünç alma işlemlerini yönetmek üzere geliştirilen bir **Kütüphane Yönetim Sistemidir**. Projede modern teknolojiler olan **Django REST**, **React**, **MySQL**, **Docker**, **Terraform**, **Jenkins**, ve **AWS servisleri** entegre şekilde kullanılmıştır.

## 🚀 Teknolojiler ve Mimariler

| Katman       | Teknoloji                                        |
|--------------|--------------------------------------------------|
| Frontend     | React + TypeScript                               |
| Backend      | Django REST Framework                            |
| Veritabanı   | MySQL (AWS RDS)                                  |
| Container    | Docker + Docker Hub                              |
| CI/CD        | Jenkins + GitHub Integration                     |
| Altyapı      | Terraform (VPC, EC2, ALB, RDS, ASG, Bastion, SG) |
| Cloud        | AWS (EC2, RDS, ALB, S3, DynamoDB)                |

## 🧱 3-Tier Mimarisi

Bu sistem, 3 katmanlı mimariyi temel alır:

- **Frontend EC2 (Private Subnet)**
- **Backend EC2 (Private Subnet)**
- **MySQL Veritabanı (Private Subnet, RDS)**
- **Load Balancer + Jenkins + Bastion (Public Subnet)**

## 📁 Proje Yapısı

```text
book/
├── backend/                 # Django uygulaması
├── frontend/                # React uygulaması
├── infra/                   # Terraform altyapısı
│   ├── aws-resources/       # VPC, EC2, RDS kaynakları
│   └── jenkins-infra/       # Jenkins kurulumu ve remote backend
├── Jenkinsfile-deploy       # Uygulama dağıtımı için pipeline
├── Jenkinsfile-infra        # Altyapı oluşturma pipeline'ı
├── Jenkinsfile-infra-destroy# Kaynakları silme pipeline'ı
├── docker-compose.yml       # Lokal geliştirme ortamı
└── README.md                # Proje dokümantasyonu
```

## 🧰 Gereksinimler

- Terraform v1.3+
- docker
- git
- AWS CLI (`aws configure` yapılmış olmalı)
- AWS hesabında EC2, IAM, VPC, S3, DynamoDB kaynaklarını oluşturma yetkisi

## 🛠️ Lokal Ortamda Başlatma (Docker)

```bash
git clone https://github.com/hakanbayraktar/book.git
cd book
docker compose up -d
```
### Erişim Bilgileri

- 🌐 Frontend: <http://localhost:8080>
- 🌐 Backend: <http://localhost:8000>
- 🔐 Django Admin: <http://localhost:8000/admin>

### 👤 Örnek Kullanıcılar

```text
Rol               E-posta            Şifre
Admin        <admin@admin.com>       admin123
Öğrenci      <student@test.com>      student123
Kütüphaneci  <librarian@test.com>    librarian123
```

### 🌐 API Endpoint’leri

```text
Endpoint Açıklama
POST /api/auth/login/ Giriş
POST /api/auth/register/ Kayıt (öğrenci)
GET /api/books/ Kitap listesi
POST /api/books/ Yeni kitap ekleme (admin)
GET /api/students/ Öğrenci listesi (admin)
POST /api/loans/ Kitap ödünç alma
PUT /api/loans/<id>/ Kitap iade

```
## ☁️ AWS Üzerinde Altyapı Kurulumu (Terraform)
Terraform ile Jenkins ve temel ağ altyapısı (VPC, subnet, bastion) Uygulamanın çalıştığı altyapı (EC2, ALB, RDS, ASG) kurulur

### ✅ Çalıştırmadan Önce Kontrol Listesi

- [ ] S3 bucket adı kontrolü
- [ ] `infra/aws-resources/remote-state.tf` dosyası
- [ ] `Jenkinsfile-infra`
- [ ] `Jenkinsfile-infra-destroy`
- [ ] `infra/jenkins-infra/terraform.tfvars` dosyası
- [ ] AWS CLI ile S3 bucket oluşturma ve silme komutları

### 1️⃣ Remote Backend Oluştur (S3 + DynamoDB)

```bash
cd infra/jenkins-infra
# S3 bucket oluşturma

aws s3api create-bucket \
  --bucket tf-state-hakan \
  --region us-east-1

# DynamoDB tablo oluşturma
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
  ```

### 2️⃣ Jenkins Altyapısını Kur

```bash
terraform init \
  -backend-config="bucket=tf-state-hakan" \
  -backend-config="key=jenkins/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks"

terraform validate
terraform plan
terraform apply -auto-approve
```

🌐 Jenkins Arayüzüne Giriş
🔑 İlk Admin Şifresi Alımı

```bash

chmod 400 infra/jenkins-infra/jenkins-key.pem
ssh -i jenkins-key.pem ubuntu@<JENKINS_PUBLIC_IP>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Tarayıcıdan: http://<jenkins-public-ip>:8080

şifreyi girdikten sonra wizard'daki talimatları takip ederek kurulumu tamamlayın.


### 🔌 Jenkins Plugin ve Credential Ayarları

🧪 Kullanılan Jenkins Plugin’leri
- AWS Credentials
- Docker Pipeline
- Pipeline Stage View
- SSH Agent
- GitHub Integration
- Blue Ocean (opsiyonel)
- Rebuilder

### Plugin’leri

Manage Jenkins > Manage Plugins > Available sekmesinden yükleyebilirsiniz.

### 🔑 Jenkins Credentials (Global → Add Credentials)

| Secret Adı         | Tür                | Açıklama               |
|--------------------|--------------------|------------------------|
| `aws-creds`        | AWS Credentials    | AWS Erişim Bilgileri   |
| `docker-creds`     | Username/Password  | DockerHub Hesabı       |
| `github-auth`      | Username/Password  | GitHub PAT             |
| `db_username`      | Secret Text        | MySQL kullanıcı adı    |
| `db_password`      | Secret Text        | MySQL şifresi          |
| `django_secret_key`| Secret Text        | Django Secret Key      |


### Credantials ekleme

Dashboard > Manage Jenkins > Credentials > System > Global credentials bölümünden Add credentials butonuna tıklayarak Jenkinsfile'da tanımlanan credential'ları ekleyebilirsiniz

### 🔧 Jenkins Pipeline Kurulumu

| Pipeline Adı         | Dosya                    | Açıklama                                |
|----------------------|--------------------------|------------------------------------------|
| `infra-create`       | `Jenkinsfile-infra`       | AWS altyapısını oluşturur               |
| `docker-deploy`      | `Jenkinsfile-deploy`      | Docker imajları oluşturur + deploy eder |
| `destroy-aws-infra`  | `Jenkinsfile-infra-destroy`| Altyapıyı siler

### 🧨 Altyapı Temizliği
- 1-Jenkins destroy job → destroy-aws-infra

- 2-Ardından manuel:

Silme işlemi tamamlandıktan sonra infra/jenkins-infra bölümünde komutlarla oluşturduğumuz kaynakları manuel olarak silmemiz gerekiyor.

```bash
cd infra/jenkins-infra
terraform destroy
```

Silme işlemine onay verdikten sonra terraform ile oluşturulan tüm kaynaklar silinecektir.

- 3-Remote backend'i temizlemek için:

```bash
aws s3 rm s3://tf-state-hakan --recursive
aws s3api delete-bucket --bucket tf-state-hakan-1 --region us-east-1
aws dynamodb delete-table --table-name terraform-locks --region us-east-1
```

🔔 Not: Silme işlemi geri alınamaz. Sadece proje tamamlandıktan ve tüm kaynaklar gereksiz hale geldikten sonra bu işlemi uygulayın.
