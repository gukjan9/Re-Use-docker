#!/bin/bash

echo "***** Executing init_process.sh *****"

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  docker compose -f docker-compose.pi.yml down spring
  docker compose -f docker-compose.pi.yml pull spring
  docker compose -f docker-compose.pi.yml up -d spring
else
  echo "$os_version"
  docker-compose -f docker-compose.yml down spring
  docker-compose -f docker-compose.yml pull spring
  docker-compose -f docker-compose.yml up -d spring
fi

echo "***** init_process.sh Ended *****"
