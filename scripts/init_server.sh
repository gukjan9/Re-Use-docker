# sudo apt-get update
# sudo apt-get upgrade
# sudo apt-get install git
# git init
# git remote add origin https://github.com/gukjan9/Re-Use-docker.git
# git pull origin main

#!/bin/bash

echo "***** Executing init_server.sh *****"

# env 파일 이동
echo "Moving env files... [1/11]"
sudo mv set_env.sh ~/scripts
sudo mv service-url-blue.inc ~/nginx/conf.d
sudo mv service-url-green.inc ~/nginx/conf.d

# .env 파일 로드
echo "Loading .env... [2/11]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# OS 버전을 확인
os_version=$(uname -a)

# 필요한 패키지 설치
echo "Installing Docker... [3/11]"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl apt-transport-https ca-certificates gnupg-agent software-properties-common

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  # Docker의 공식 GPG 키 추가
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # Docker 의 공식 apt 저장소 추가
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
  echo "$os_version"
  # Docker의 공식 GPG 키 추가
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # Docker 의 공식 apt 저장소 추가
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
fi

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# docker group 에 사용자 추가
sudo usermod -aG docker $USER
newgrp docker << 'EOF'

echo "[Sub Shell]"

# Docker 서비스 시작
sudo systemctl start docker

# Docker가 정상적으로 설치되었는지 확인
docker --version

# Docker Hub에 로그인
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

# Docker-compose 설치
echo "Installing Docker-Compose... [4/11]"
if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt install docker-compose
else
  echo "$os_version"
  sudo apt-get update
  sudo apt-get install docker-compose-plugin
fi

sudo chmod +x /usr/local/bin/docker-compose

# MySQL 데이터 복원
echo "Restoring MySQL data... [5/11]"
source ./scripts/restore_data.sh

echo "Setting Crontab... [6/11]"
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

# Docker 네트워크 생성
echo "Creating docker network... [7/11]"
docker network create --driver bridge $DOCKER_NETWORK

# SSH Port 변경
# 보안그룹에 포트를 지정해주거나 포트포워딩이 선행 되어야 한다.
echo "Setting custom ssh port... [8/11]"
source ./scripts/set_ssh_port.sh

# 추가 패키지 설치
echo "Installing packages... [9/11]"

# swap 영역 생성
echo "Creating swap file... [10/11]"
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo vi /etc/fstab
/swapfile swap swap defaults 0 0
free

# bashrc 에 startup_server_log 로깅 추가
echo "Tail startup_server_log.txt after reboot... [11/11]"
if ! grep -q "tail -f ~/cron_logs/startup_server_log.txt" ~/.bashrc; then
    echo "tail -f ~/cron_logs/startup_server_log.txt" >> ~/.bashrc
fi

echo "***** init_server.sh Ended *****"

EOF

echo "Rebooting Server..."
sudo reboot
