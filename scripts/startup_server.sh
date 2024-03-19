#!/bin/bash

echo "***** Executing startup_server.sh *****"

# .env 파일 로드
echo "Loading .env... [1/5]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 포트포워딩
echo "Setting port forwarding... [2/5]"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $SSH_PORT

# Docker 재시작
echo "Restarting docker... [3/5]"
sudo service docker restart

# 서버 init 여부
INIT_FLAG="$HOME/.init_configured"

if [ ! -f "$MYSQL_PRIVILEGES_CONFIGURED_FLAG" ]; then

  # Process 실행
  echo "Running server... [4/5]"
  source ~/scripts/init_process.sh

  # MySQL 권한 부여
  echo "Initializing mysql privileges... [5/5]"
  # docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE1' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE1'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE2' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_BLUE'@'$MYSQL_ALLOWED_IP_RANGE2'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE1' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE1'; FLUSH PRIVILEGES;"
  docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE2' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME_GREEN'@'$MYSQL_ALLOWED_IP_RANGE2'; FLUSH PRIVILEGES;"

  # Flag 파일 생성
  touch "$INIT_FLAG"

else
  echo "Server already initialized. Skipping... [5/5]"
fi

echo "***** startup_server.sh Ended *****"
