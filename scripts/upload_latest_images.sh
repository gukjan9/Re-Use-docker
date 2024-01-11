#!/bin/bash

echo "***** Executing upload_latest_images.sh *****"

# .env 파일 로드
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# Docker Hub에 로그인
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

# 특정 컨테이너 이름 설정 (예: mysql과 redis)
containers_to_upload=("mysql-reuse" "redis-reuse")

# 선택된 컨테이너만 업로드
for container_name in "${containers_to_upload[@]}"; do
    # 컨테이너 ID 가져오기
    container_id=$(docker ps -q -f name="$container_name")

    # 컨테이너 ID가 존재하면 처리
    if [ ! -z "$container_id" ]; then
        # 컨테이너 ID로부터 이미지 이름 생성
        image_name="${container_name}:latest"

        # 컨테이너를 이미지로 커밋
        docker commit "$container_id" "$image_name"

        # 이미지를 Docker Hub 사용자의 레포지토리로 태그 지정
        docker tag "$image_name" "$DOCKER_USERNAME/$image_name"

        # Docker Hub에 이미지 푸시
        docker push "$DOCKER_USERNAME/$image_name"
    else
        echo "No running container found for $container_name"
    fi
done

echo "***** upload_latest_images.sh Ended *****"
