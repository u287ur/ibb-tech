# 🏥 PetClinic – Jenkins ile Blue/Green Deployment (AWS EKS)

Bu proje, **Spring PetClinic** uygulamasını **Jenkins pipeline** kullanarak **Blue/Green metodolojisi** ile **AWS EKS** üzerine kesintisiz ve güvenli bir şekilde deploy etmeyi amaçlar.  
Tüm altyapı otomasyonla kurulup, kod kalitesi ve güvenlik analizleri entegre edilmiştir.

## ⚙️ Kullanılan Teknolojiler

- 🛠️ **Jenkins** → CI/CD yönetimi, parametrik pipeline
- ☸️ **Kubernetes (AWS EKS)** → Blue/Green uygulama dağıtımı
- 🐳 **Docker** → Container build & push
- 🧪 **Trivy** → Container güvenlik tarama aracı
- 📊 **SonarQube** → Kod kalitesi analizi
- 🐘 **MySQL** → StatefulSet ile kalıcı veritabanı
- 🧾 **eksctl + kubectl + helm** → EKS ve servis kurulumları
- 🔐 **GitHub Credentials + DockerHub + AWS IAM** → güvenli erişim

---

## 🧱 3 Katmanlı Mimari

1. **Application Layer**
   - Spring Boot tabanlı PetClinic
   - Blue ve Green deployment olarak 2 ortamda çalışır
   - Trafiğin yönü `petclinic-service.yaml` ile değiştirilir

2. **Database Layer**
   - MySQL veritabanı StatefulSet olarak deploy edilir
   - Secret & ConfigMap ile yapılandırma

3. **CI/CD Layer**
   - Jenkins → `infra-create`, `bluegreen-deploy`, `destroy-infra`
   - Parametrik deploy: `DEPLOY_ENV=BLUE` veya `GREEN`
   - Docker image + SonarQube + Trivy + Kubectl ile otomasyon

---

## 📂 Proje Yapısı

```bash
├── infra # Jenkins ve SonarQube kurulum scriptleri
├── k8s # Kubernetes deployment/service dosyaları
├── src # Java kaynak kodları
├── Jenkinsfile-bluegreen-deploy # Blue/Green deployment Jenkinsfile'ı
├── Jenkinsfile-infra-create # EKS cluster oluşturma pipeline'ı
├── Jenkinsfile-infra-destroy # EKS cluster silme pipeline'ı
├── Dockerfile # Docker imajı oluşturma tanımı
├── pom.xml # Maven yapılandırması
├── sonar-project.properties # SonarQube konfigürasyonu
└── README.md # Proje dökümantasyonu

```

## 🚀 Kurulum Adımları

### 1️⃣ SonarQube Sunucusu

```bash
cd infra
bash sonarqube-install.sh
```
Arayüz: http://SonarQube-IP:9000

Giriş bilgileri: admin / admin

Token oluşturmak için:
Account → My account → Security → Generate Token

Bu token'ı Jenkins’te sonar-token olarak tanımlayın.

### 2️⃣ Jenkins Sunucusu

```bash
cd infra
bash jenkins-install.sh
```
Arayüz: http://Jenkins-IP:8080
Giriş şifresi almak için:

```bash
ssh -i jenkins-key.pem ubuntu@<Jenkins-IP>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 🔌 Jenkins Plugin ve Credential Ayarları

🧪 Kullanılan Jenkins Plugin’leri

- AWS Credentials
- Docker Pipeline
- Pipeline Stage View
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
| `sonar-token`      | Secret Text        | sonarqube Token        |
| `sonar-url`        | Secret Text        | Sonar IP:port          |


### Credantials ekleme

Dashboard > Manage Jenkins > Credentials > System > Global credentials bölümünden Add credentials butonuna tıklayarak Jenkinsfile'da tanımlanan credential'ları ekleyebilirsiniz

## 🔧 Jenkins Pipeline Kurulumu

### 🔨 infra-create – EKS Cluster Oluşturma
🚧 Altyapıyı kuran ana pipeline
- Yeni Pipeline oluşturun
- Adı: infra-create
- Script Path: Jenkinsfile-infra-create
- Kaynak: <https://github.com/hakanbayraktar/blue-green.git>

✅ Bu job yalnızca ilk kurulumda çalıştırılır.
Kurulumdan sonra cluster’a erişmek için:

```bash
aws eks update-kubeconfig --region us-east-1 --name bluegreen-cluster
```

### 🚀 2. blue-green – Blue/Green Deployment
🔁 Blue/Green metodolojisi ile uygulama güncellemeleri yapar
Bu pipeline, her yeni versiyon deploy etmek istediğinde çalıştırılır.
Pipeline başında DEPLOY_ENV olarak BLUE veya GREEN seçilir.
- Pipeline Adı: blue-green
- Script Path: Jenkinsfile-bluegreen-deploy
- Kaynak: <https://github.com/hakanbayraktar/blue-green.git>
- Parametreli çalıştır: blue veya green seçilerek

### 📦 Aşamaları:

- Maven ile uygulama derlenir
- Anasayfa HTML dosyasına seçilen renk (BLUE veya GREEN) yazılır
- Docker image build edilir, DockerHub’a push edilir
- Trivy ile container güvenlik taraması yapılır
- SonarQube ile kod analizi gerçekleştirilir
- Kubernetes’e yeni versiyon (blue/green) deploy edilir
- Sağlıklı ise service.yaml ile trafik yeni versiyona yönlendirilir
- Eski versiyon otomatik olarak silinir (kubectl delete deployment)

🟢 Kesintisiz güncelleme sağlar: Uygulamanız her zaman erişilebilir kalır.

### 🧭 Blue/Green Deploy Ne Zaman Kullanılır?

- Canlı sistemde kesinti olmadan yeni versiyon denemek istiyorsan
- Yeni kodu önce sadece belirli trafiğe yönlendirmek, sonra yaygınlaştırmak istiyorsan
- Güncellemeden sonra geri dönüş (rollback) ihtimalin varsa

🎯 Bu yapı sayesinde, aynı anda iki versiyon (blue/green) sistemde var olabilir.
Kullanıcı trafiği sadece "aktif" olan servise yönlendirilir. Yeni versiyon stabilse, yön değiştirilir

### 🌐 Uygulama Erişimi

<http://LOAD_BALANCER_DNS_NAME>
LoadBalancer DNS adresini öğrenmek için:
```bash
kubectl get svc 
```
Deploy edilen versiyon (BLUE or GREEN) anasayfada yazıyla görünür.

### 🧨 3.infra-destroy – EKS Cluster Silme

🧹 EKS Cluster’ı siler

- Pipeline adı: infra-destroy
- Script Path: Jenkinsfile-infra-destroy
- Kaynak: <https://github.com/hakanbayraktar/blue-green.git>

Build Now ile çalıştırın (kullanıcı onayı alınır)

### 🧹 Manuel Temizlik
Aşağıdaki script’ler ile Jenkins ve SonarQube sunucularını da silebilirsiniz:
```bash
cd infra
# Jenkins ve SonarQube sunucusunu silmek için
bash destroy-jenkins-sonar.sh
```
### ✅ Sonuç
Bu proje sayesinde:
- Jenkins ile eksiksiz bir CI/CD yapısı kurduk
- Blue/Green deployment ile canlıda sıfır kesintili geçiş sağladık
- Kod kalitesi ve güvenlik kontrolünü pipeline'a entegre ettik
- AWS EKS üzerinde production benzeri bir ortam kurduk
