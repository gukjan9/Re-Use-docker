#!/bin/bash

echo "***** Executing init_process.sh *****"

# .env 파일 로드
echo "Loading .env... [1/6]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

IS_BLUE=$(docker ps | grep ${SPRING_CONTAINER_NAME}-blue)
MAX_RETRIES=20

check_service() {
  local RETRIES=0
  local URL=$1
  while [ $RETRIES -lt $MAX_RETRIES ]; do
    echo "Checking service at $URL... (attempt: $((RETRIES+1)))"
    sleep 3

    REQUEST=$(curl $URL)
    if [ -n "$REQUEST" ]; then
      echo "health check success"
      return 0
    fi

    RETRIES=$((RETRIES+1))
  done;

  echo "Failed to check service after $MAX_RETRIES attempts."
  return 1
}

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"

  if [ -z "$IS_BLUE" ];then
    docker compose -f docker-compose.pi.yml down spring-blue
    docker compose -f docker-compose.pi.yml pull spring-blue
    docker compose -f docker-compose.pi.yml up -d spring-blue

    sleep 30

    docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"


    if ! check_service "$SERVER_IP_BLUE"; then
      echo "SPRING-BLUE health check failed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-blue
      docker compose rm -f spring-blue
    else
      echo "SPRING-BLUE health check succeed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-green
      docker compose rm -f spring-green
    fi

  else
    docker compose -f docker-compose.pi.yml down spring-green
    docker compose -f docker-compose.pi.yml pull spring-green
    docker compose -f docker-compose.pi.yml up -d spring-green

    sleep 30

    docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"


    if ! check_service "$SERVER_IP_BLUE"; then
      echo "SPRING-BLUE health check failed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-blue
      docker compose rm -f spring-blue
    else
      echo "SPRING-BLUE health check succeed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-green
      docker compose rm -f spring-green
    fi
  fi

else
  echo "$os_version"

  if [ -z "$IS_BLUE" ];then
    docker-compose -f docker-compose.yml down spring-blue
    docker-compose -f docker-compose.yml pull spring-blue
    docker-compose -f docker-compose.yml up -d spring-blue

    sleep 30

    docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"


    if ! check_service "$SERVER_IP_BLUE"; then
      echo "SPRING-BLUE health check failed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-blue
      docker compose rm -f spring-blue
    else
      echo "SPRING-BLUE health check succeed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-green
      docker compose rm -f spring-green
    fi

  else
    docker-compose -f docker-compose.yml down spring-green
    docker-compose -f docker-compose.yml pull spring-green
    docker-compose -f docker-compose.yml up -d spring-green

    sleep 30

    docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_DATABASE_PASSWORD <<< "CREATE USER '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP' IDENTIFIED BY '$MYSQL_DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_DATABASE_USERNAME'@'$MYSQL_ALLOWED_IP'; FLUSH PRIVILEGES;"


    if ! check_service "$SERVER_IP_BLUE"; then
      echo "SPRING-BLUE health check failed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-blue
      docker compose rm -f spring-blue
    else
      echo "SPRING-BLUE health check succeed"

      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/nginx.conf
      sudo nginx -s reload

      docker compose stop spring-green
      docker compose rm -f spring-green
    fi
  fi
fi

echo "***** init_process.sh Ended *****"
