#!/bin/bash

echo "***** Executing startup_server.sh *****"

# 포트포워딩
echo "Setting port forwarding... [1/4]"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"

  # /etc/resolv.conf 파일을 확인하고, nameserver가 없으면 추가
  if ! grep -q "nameserver 8.8.8.8" /etc/resolv.conf; then
      echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
  fi

  if ! grep -q "nameserver 8.8.4.4" /etc/resolv.conf; then
      echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
  fi
fi

# Docker 재시작
echo "Restarting docker... [2/4]"
source ~/scripts/restart_docker.sh

# Process 실행
echo "Running server... [3/4]"
source ~/scripts/run_new_process.sh

# MySQL 권한 부여
echo "Initializing mysql privileges... [4/4]"
docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"

echo "***** startup_server.sh Ended *****"
