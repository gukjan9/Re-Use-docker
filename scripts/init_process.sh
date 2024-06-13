#!/bin/bash

echo "***** Executing init_process.sh *****"

# .env 파일 로드
echo "Loading .env... [1/3]"
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

  echo "Pulling spring image... [2/3]"
  docker compose -f docker-compose.pi.yml down
  docker compose -f docker-compose.pi.yml pull

  # 이미지 생성일 확인
  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running SPRING-BLUE... [3/3]"
    docker compose -f docker-compose.pi.yml up -d
    docker compose -f docker-compose.pi.yml down spring-green
  else
    echo "Running SPRING_GREEN... [3/3]"
    docker compose -f docker-compose.pi.yml up -d
    docker compose -f docker-compose.pi.yml down spring-blue
  fi

else
  echo "$os_version"

  echo "Pulling spring image... [2/3]"
  docker compose -f docker-compose.yml down
  docker compose -f docker-compose.yml pull

  # 이미지 생성일 확인
  BLUE_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:blue")
  GREEN_CREATED=$(docker inspect --format '{{ .Created }}' "${DOCKER_USERNAME}/${SPRING_CONTAINER_NAME}:green")

  if [[ "$BLUE_CREATED" > "$GREEN_CREATED" ]]; then
    echo "Running SPRING-BLUE... [3/3]"
    docker compose -f docker-compose.yml up -d
    docker compose -f docker-compose.yml down spring-green
  else
    echo "Running SPRING_GREEN... [3/3]"
    docker compose -f docker-compose.yml up -d
    docker compose -f docker-compose.yml down spring-blue
  fi
fi

echo "Sleeping for 30 seconds..."
sleep 30

echo "***** init_process.sh Ended *****"
