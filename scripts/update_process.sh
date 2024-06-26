#!/bin/bash

echo "***** Executing update_process.sh *****"

# .env 파일 로드
echo "Loading .env... [1/5]"
ENV_FILE="$HOME/.env_v1"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  docker compose -f docker-compose.pi.yml pull spring-blue spring-green
else
  docker compose -f docker-compose.yml pull spring-blue spring-green
fi

# 이미지 생성일 확인
BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

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

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running lastest service... [2/5]"
    docker compose -f docker-compose.pi.yml up -d spring-blue

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "http://${SERVER_IP}:${SERVICE_PORT_BLUE}${HEALTH_CHECK}"; then
      docker compose stop spring-blue
      docker compose rm -f spring-blue
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      export SERVICE_URL=${SERVER_IP}:${SERVICE_PORT_BLUE}
      envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-green
      docker compose rm -f spring-green

      echo "Service port successfully had switched green -> blue"
    fi

  else
    echo "Running lastest service... [2/5]"
    docker compose -f docker-compose.pi.yml up -d spring-green

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "http://${SERVER_IP}:${SERVICE_PORT_GREEN}${HEALTH_CHECK}"; then
      docker compose stop spring-green
      docker compose rm -f spring-green
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      export SERVICE_URL=${SERVER_IP}:${SERVICE_PORT_GREEN}
      envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-blue
      docker compose rm -f spring-blue

      echo "Service port successfully had switched blue -> green"
    fi
  fi

else
  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running lastest server... [2/5]"
    docker compose -f docker-compose.yml up -d spring-blue

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "http://${SERVER_IP}:${SERVICE_PORT_BLUE}${HEALTH_CHECK}"; then
      docker compose stop spring-blue
      docker compose rm -f spring-blue
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      export SERVICE_URL=${SERVER_IP}:${SERVICE_PORT_BLUE}
      envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-green
      docker compose rm -f spring-green

      echo "Service port successfully had switched green -> blue"
    fi

  else
    echo "Running lastest server... [2/5]"
    docker compose -f docker-compose.yml up -d spring-green

    for i in {30..1}; do
      echo -ne "Waiting for $i seconds...\r"
      sleep 1
    done

    echo "Starting health check... [3/5]"
    if ! check_service "http://${SERVER_IP}:${SERVICE_PORT_GREEN}${HEALTH_CHECK}"; then
      docker compose stop spring-green
      docker compose rm -f spring-green
      echo "Failed to switching server"
    else
      echo "Reloading Nginx... [4/5]"
      export SERVICE_URL=${SERVER_IP}:${SERVICE_PORT_GREEN}
      envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
      docker exec $NGINX_CONTAINER_NAME nginx -s reload

      echo "Shutting down the previous server... [5/5]"
      docker compose stop spring-blue
      docker compose rm -f spring-blue

      echo "Service port successfully had switched blue -> green"
    fi
  fi
fi

echo "***** update_process.sh Ended *****"
