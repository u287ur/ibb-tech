#!/bin/bash
set -e

TAG_KEY="Name"
TAG_VALUE="JenkinsServer"
KEY_NAME="jenkins-key"

echo "🔍 Jenkins EC2 instance 'Name=$TAG_VALUE' etiketi ile aranıyor..."

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" "Name=instance-state-name,Values=running,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCE_ID" ]; then
  echo "⚠️ Jenkins EC2 bulunamadı veya zaten silinmiş."
  exit 0
fi

echo "🆔 Bulunan EC2 Instance ID: $INSTANCE_ID"

# Public IP bilgisi gösterelim
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo -e "\n🌐 EC2 Public IP: \033[1;34mhttp://$PUBLIC_IP:8080\033[0m"

# Kullanıcıdan onay alalım
read -p $'\n⚠️ \033[1;31mBu işlem Jenkins sunucusunu kalıcı olarak silecek. Devam etmek istiyor musunuz?\033[0m (yes/no): ' confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Silme işlemi iptal edildi."
  exit 1
fi

# EC2'yi sil
echo "🗑️ EC2 instance siliniyor..."
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

# Key dosyasını da sil (opsiyonel)
if [ -f "${KEY_NAME}.pem" ]; then
  echo "🧹 SSH anahtarı siliniyor: ${KEY_NAME}.pem"
  rm -f "${KEY_NAME}.pem"
fi

echo -e "\n✅ \033[1;32mJenkins EC2 başarıyla silindi.\033[0m"
