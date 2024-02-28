#!/bin/bash

echo "***** Executing update_process.sh *****"

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

# 실행되고 있는 이미지 태그 조회
IS_BLUE=$(docker ps | grep ${SPRING_CONTAINER_NAME}-blue)
MAX_RETRIES=20

# health check
check_service() {
  local RETRIES=0
  local URL=$1
  while [ $RETRIES -lt $MAX_RETRIES ]; do
    echo "Checking service... (attempt: $((RETRIES+1)))"
    sleep 3

    REQUEST=$(curl $URL)
    if [ -n "$REQUEST" ]; then
      echo "Health check success"
      return 0
    fi

    RETRIES=$((RETRIES+1))
  done;

  echo "Failed to check service after $MAX_RETRIES attempts"
  return 1
}

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"

  if [ -z "$IS_BLUE" ];then
    echo "Running lastest service... [2/5]"
    docker compose -f docker-compose.pi.yml pull spring-blue
    docker compose -f docker-compose.pi.yml up -d spring-blue

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "$SERVER_IP_BLUE"; then
      docker compose stop spring-blue
      docker compose rm -f spring-blue
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-green
      docker compose rm -f spring-green

      echo "Service port successfully had switched green -> blue"
    fi

  else
    echo "Running lastest service... [2/5]"
    docker compose -f docker-compose.pi.yml pull spring-green
    docker compose -f docker-compose.pi.yml up -d spring-green

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "$SERVER_IP_GREEN"; then
      docker compose stop spring-green
      docker compose rm -f spring-green
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_green.conf /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-blue
      docker compose rm -f spring-blue

      echo "Service port successfully had switched blue -> green"
    fi
  fi

else
  echo "$os_version"

  if [ -z "$IS_BLUE" ];then
    echo "Running lastest server... [2/5]"
    docker-compose -f docker-compose.yml pull spring-blue
    docker-compose -f docker-compose.yml up -d spring-blue

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "$SERVER_IP_BLUE"; then
      docker compose stop spring-blue
      docker compose rm -f spring-blue
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_blue.conf /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-green
      docker compose rm -f spring-green

      echo "Service port successfully had switched green -> blue"
    fi

  else
    echo "Running lastest server... [2/5]"
    docker-compose -f docker-compose.yml pull spring-green
    docker-compose -f docker-compose.yml up -d spring-green

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "$SERVER_IP_GREEN"; then
      docker compose stop spring-green
      docker compose rm -f spring-green
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      sudo cp /home/$SSH_USERNAME/nginx/conf.d/nginx_green.conf /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-blue
      docker compose rm -f spring-blue

      echo "Service port successfully had switched blue -> green"
    fi
  fi
fi

echo "***** update_process.sh Ended *****"
