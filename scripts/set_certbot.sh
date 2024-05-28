#!/bin/bash

echo "***** Executing set_certbot.sh *****"

# .env 파일 로드
echo "Loading .env... [1/3]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# certbot 설치
echo "Installing Certbot... [2/3]"
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo apt-get install certbot -y
certbot --version

# 스크립트 실행 성공 후 crontab 설정
echo "Setting Crontab... [3/3]"
if [ $? -eq 0 ]; then
  (crontab -l 2>/dev/null; echo "0 17 1 * * /usr/bin/certbot renew --renew-hook='sudo cp /etc/letsencrypt/live/reuse.kro.kr/fullchain.pem /home/${SSH_USERNAME}/nginx/conf.d/ && sudo cp /etc/letsencrypt/live/reuse.kro.kr/privkey.pem /home/${SSH_USERNAME}/nginx/conf.d/ && docker exec $NGINX_CONTAINER_NAME nginx -s reload'") | crontab -
  echo "Crontab updated successfully"
else
  echo "Failed to setting crontab"
fi

echo "***** set_certbot.sh Ended *****"
