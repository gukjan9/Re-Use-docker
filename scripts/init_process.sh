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

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  docker compose -f docker-compose.pi.yml down
  docker compose -f docker-compose.pi.yml pull

  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running SPRING-BLUE"
    docker compose -f docker-compose.pi.yml up -d nginx redis mysql spring-blue
  else
    echo "Running SPRING_GREEN"
    docker compose -f docker-compose.pi.yml up -d nginx redis mysql spring-green
  fi

else
  echo "$os_version"
  docker compose -f docker-compose.yml down
  docker compose -f docker-compose.yml pull

  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running SPRING-BLUE"
    docker compose -f docker-compose.yml up -d nginx redis mysql spring-blue
  else
    echo "Running SPRING_GREEN"
    docker compose -f docker-compose.yml up -d nginx redis mysql spring-green
  fi
fi

echo "***** init_process.sh Ended *****"
