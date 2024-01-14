#apt-get update
#apt-get upgrade
#git 설치
#git clone docker repo

#docker 설치
#docker-compose 설치
#docker login

echo "***** Executing init_server.sh *****"

# Docker의 공식 GPG 키 추가
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker 서비스 시작
sudo systemctl start docker

# Docker가 정상적으로 설치되었는지 확인
docker --version

echo "***** init_server.sh Ended *****"
