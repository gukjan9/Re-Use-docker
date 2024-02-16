#!/bin/bash

echo "***** Executing remove_idle_images.sh *****"

# .env 파일 로드
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 현재 실행 중인 컨테이너의 이미지 ID를 가져옴
running_images=$(docker ps --format "{{.Image}}")

# 중지된 컨테이너 목록 조회
docker ps -a -f "status=exited"

# 컨테이너 삭제 여부 확인
echo "Do you want to remove all stopped containers? [y/n]"
read answer

# 소문자로 변환하여 처리하기 쉽게 만들기
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

# 사용자의 답변에 따라 분기
if [ "$answer" == "y" ]; then
    echo "Removing all stopped containers..."
    docker container prune -f
    echo "All stopped containers have been removed."
elif [ "$answer" == "n" ]; then
    echo "Operation canceled."
else
    echo "Invalid input. Operation canceled."
fi

# 모든 이미지를 검사
for image in $(docker images --format "{{.Repository}}:{{.Tag}}@{{.ID}}"); do
    repo=$(echo $image | cut -d':' -f1)
    tag=$(echo $image | cut -d':' -f2 | cut -d'@' -f1)
    image_id=$(echo $image | cut -d'@' -f2)

    # 조건 체크: 이미지 이름이 DOCKER_USERNAME/로 시작하지 않거나, 태그가 latest, rebuild, stable이 아님
    if [[ ! $repo =~ ^${DOCKER_USERNAME}/ || ! $tag =~ ^(latest|rebuild|stable|blue|green)$ ]]; then
        # 현재 실행 중인 컨테이너에서 사용되고 있지 않은지 확인
        if [[ ! $running_images =~ $image_id ]]; then
            echo "Delete Image: $image"
            docker rmi -f $image_id
        else
            echo "Image in use, skipping...: $image"
        fi
    else
        echo "Does not meet the criteria, skipping...: $image"
    fi
done

echo "***** remove_idle_images.sh Ended *****"
