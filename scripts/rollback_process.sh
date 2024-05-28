#!/bin/bash

echo "***** Executing rollback_process.sh *****"

# .env 파일 로드
echo "Loading .env... [1/4]"
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

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"

  # 이미지 생성일 확인
  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Rollbacking to SPRING-GREEN... [2/4]"

    echo "Reloading Nginx... [3/4]"
    export SERVICE_URL=http://${SERVER_IP}:${SERVICE_PORT_GREEN}
    envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
    docker exec $NGINX_CONTAINER_NAME nginx -s reload

    echo "Shutting down the previous server... [4/4]"
    docker compose stop spring-blue
    docker compose rm -f spring-blue

    docker compose -f docker-compose.pi.yml up -d spring-green

    echo "Service port successfully had rollbacked blue -> green"
  else
    echo "Rollbacking to SPRING-BLUE... [2/4]"

    echo "Reloading Nginx... [3/4]"
    export SERVICE_URL=http://${SERVER_IP}:${SERVICE_PORT_BLUE}
    envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
    docker exec $NGINX_CONTAINER_NAME nginx -s reload

    echo "Shutting down the previous server... [4/4]"
    docker compose stop spring-green
    docker compose rm -f spring-green

    docker compose -f docker-compose.pi.yml up -d spring-blue

    echo "Service port successfully had rollbacked green -> blue"
  fi

else
  echo "$os_version"

  # 이미지 생성일 확인
  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Rollbacking to SPRING-GREEN... [2/4]"

    echo "Reloading Nginx... [3/4]"
    export SERVICE_URL=http://${SERVER_IP}:${SERVICE_PORT_GREEN}
    envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
    docker exec $NGINX_CONTAINER_NAME nginx -s reload

    echo "Shutting down the previous server... [4/4]"
    docker compose stop spring-blue
    docker compose rm -f spring-blue

    docker compose -f docker-compose.yml up -d spring-green

    echo "Service port successfully had rollbacked blue -> green"
  else
    echo "Rollbacking to SPRING-BLUE... [2/4]"

    echo "Reloading Nginx... [3/4]"
    export SERVICE_URL=http://${SERVER_IP}:${SERVICE_PORT_BLUE}
    envsubst "\$SERVICE_URL" < /home/$SSH_USERNAME/nginx/conf.d/default.conf.template > /home/$SSH_USERNAME/nginx/conf.d/default.conf
    docker exec $NGINX_CONTAINER_NAME nginx -s reload

    echo "Shutting down the previous server... [4/4]"
    docker compose stop spring-green
    docker compose rm -f spring-green

    docker compose -f docker-compose.yml up -d spring-blue

    echo "Service port successfully had rollbacked green -> blue"
  fi
fi

echo "Sleeping for 30 seconds..."
sleep 30

echo "***** rollback_process.sh Ended *****"
