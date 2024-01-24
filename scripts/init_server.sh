# sudo apt-get update
# sudo apt-get upgrade
# sudo apt-get install git
# git init
# git remote add origin https://github.com/gukjan9/Re-Use-docker.git
# git pull origin main

#!/bin/bash

echo "***** Executing init_server.sh *****"

# env 파일 이동
echo "Moving env files... [1/7]"
sudo mv set_env.sh ~/scripts

# .env 파일 로드
echo "Loading .env... [2/7]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 필요한 패키지 설치
echo "Installing Docker... [3/7]"
sudo apt-get update
sudo apt-get install curl apt-transport-https ca-certificates gnupg-agent software-properties-common

# Docker의 공식 GPG 키 추가
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# (pi)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker 의 공식 apt 저장소 추가
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# (pi)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# docker group 에 사용자 추가
# (pi)
sudo usermod -aG docker $USER
newgrp docker << 'EOF'

echo "[Sub Shell]"

# docker.sock 권한 변경
# (pi)
# sudo chmod 666 /var/run/docker.sock

# Docker 서비스 시작
sudo systemctl start docker

# Docker가 정상적으로 설치되었는지 확인
docker --version

# Docker Hub에 로그인
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

# Docker-compose 설치
echo "Installing Docker-Compose... [4/7]"
# sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
# (pi)
sudo apt-get install -y python3-pip
sudo pip3 install docker-compose

sudo chmod +x /usr/local/bin/docker-compose

# MySQL 데이터 복원
echo "Restoring MySQL data... [5/7]"
source ./scripts/restore_data.sh

echo "Setting Crontab... [6/7]"
SCRIPT="/home/$TARGET_SERVER_USERNAME/scripts/startup_server.sh"
chmod +x $SCRIPT

mkdir cron_logs
touch ~/cron_logs/startup_server_log.txt

# Crontab에 이미 해당 스크립트가 설정되어 있는지 확인
if crontab -l | grep -q "@reboot $SCRIPT > /home/$TARGET_SERVER_USERNAME/cron_logs/startup_server_log.txt 2>&1"; then
    echo "startup_server.sh is already set up in Crontab"
else
    # 현재 crontab을 백업하고, 새 명령어 추가
    (crontab -l 2>/dev/null; echo "@reboot $SCRIPT > /home/$TARGET_SERVER_USERNAME/cron_logs/startup_server_log.txt 2>&1") | crontab -
    echo "The script has been added to Crontab"
fi

# SSH Port 변경
# 보안그룹에 포트를 지정해주거나 포트포워딩이 선행 되어야 한다.
echo "Setting custom ssh port... [7/7]"
source ./scripts/set_ssh_port.sh

# Docker 네트워크 설정
docker network create --driver bridge $DOCKER_NETWORK

echo "***** init_server.sh Ended *****"

EOF

echo "Rebooting Server..."
sudo reboot
