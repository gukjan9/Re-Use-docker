#apt-get update
#apt-get upgrade
#git 설치
#git clone docker repo

#docker 설치
#docker-compose 설치
#docker login

echo "***** Executing init_server.sh *****"

# env 파일 이동
echo "Moving env files... [1/6]"
sudo mv set_env.sh ~/scripts

# .env 파일 로드
echo "Loading .env... [2/6]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 필요한 패키지 설치
echo "Installing Docker... [3/6]"
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# Docker의 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Docker 의 공식 apt 저장소 추가
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker 설치
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker 서비스 시작
sudo systemctl start docker

# Docker가 정상적으로 설치되었는지 확인
docker --version

# Docker Hub에 로그인
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

# Docker-compose 설치
echo "Installing Docker-Compose... [4/6]"
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# MySQL 데이터 복원
echo "Restoring MySQL data... [5/6]"
source ./scripts/restore_data.sh

echo "Setting Crontab... [6/6]"
SCRIPT="./scripts/startup_server.sh"

# Crontab에 이미 해당 스크립트가 설정되어 있는지 확인
if crontab -l | grep -q "@reboot $SCRIPT"; then
    echo "startup_server.sh is already set up in Crontab"
else
    # 현재 crontab을 백업하고, 새 명령어 추가
    (crontab -l 2>/dev/null; echo "@reboot $SCRIPT") | crontab -
    echo "The script has been added to Crontab"
fi

echo "***** init_server.sh Ended *****"

echo "Rebooting Server..."
sudo reboot
