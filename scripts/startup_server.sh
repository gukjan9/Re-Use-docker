#!/bin/bash

echo "***** Executing startup_server.sh *****"

# .env 파일 로드
echo "Loading .env... [1/7]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 포트포워딩
echo "Setting port forwarding... [2/7]"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $SSH_PORT

# .env 서버 ip 변경
echo "Updating .env IP... [3/7]"
SERVER_IP=$(curl -s ifconfig.me)
sed -i "s/^SERVER_IP=.*/SERVER_IP=$SERVER_IP/" .env

# Docker 재시작
echo "Restarting docker... [4/7]"
sudo service docker restart

# 서버 init 여부
INIT_FLAG="$HOME/.init_configured"

if [ ! -f "$MYSQL_PRIVILEGES_CONFIGURED_FLAG" ]; then

  # Process 실행
  echo "Running server... [5/7]"
  source ~/scripts/init_process.sh

  # MySQL 권한 부여
  echo "Initializing mysql privileges... [6/7]"
  # docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE1' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE1'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE2' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE2'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE1' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE1'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE2' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE2'; FLUSH PRIVILEGES;"

  # Flag 파일 생성
  touch "$INIT_FLAG"

else
  echo "Server already initialized. Skipping... [6/7]"
fi

# crontab startup_server 삭제
SCRIPT="/home/$TARGET_SERVER_USERNAME/scripts/startup_server.sh"
crontab -l | grep -v "$(echo "@reboot $SCRIPT > /home/$TARGET_SERVER_USERNAME/cron_logs/startup_server_log.txt 2>&1" | sed 's:[]\/$*.^[]:\\&:g')" | crontab -

echo "***** startup_server.sh Ended *****"
