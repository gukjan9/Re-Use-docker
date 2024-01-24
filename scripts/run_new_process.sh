#!/bin/bash

echo "***** Executing run_new_process.sh *****"

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"
  docker-compose -f docker-compose.pi.yml down
  docker-compose -f docker-compose.pi.yml pull
  docker-compose -f docker-compose.pi.yml up -d
else
  echo "$os_version"
  docker-compose -f docker-compose.yml down
  docker-compose -f docker-compose.yml pull
  docker-compose -f docker-compose.yml up -d
fi

echo "***** run_new_process.sh Ended *****"
