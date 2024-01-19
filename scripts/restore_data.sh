echo "***** Executing restore_data.sh *****"

# .env 파일 로드
echo "Loading .env... [0/3]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# Docker 볼륨 생성
echo "Creating Docker volume..."
docker volume create ${MYSQL_DATA}

# MySQL pull
docker pull mysql

# restore 용 MySQL 환경변수 설정
MYSQL_IMAGE_NAME="mysql:latest"
MYSQL_ROOT_PASSWORD="1234"
MYSQL_CONTAINER_NAME="restore_container"

# MySQL 실행
echo "Running MySQL container..."
docker run --name $MYSQL_CONTAINER_NAME -v $MYSQL_VOLUME:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d $MYSQL_IMAGE_NAME

# 백업 파일 복사
echo "Copying backup file to the container..."
docker cp /home/$TARGET_SERVER_USERNAME/backup/backup.sql $MYSQL_CONTAINER_NAME:/var/lib/mysql/backup.sql

# MySQL에 접속하여 백업 데이터 복원
echo "Restoring data from backup..."
docker exec -i $MYSQL_CONTAINER_NAME /bin/bash << EOF
mysql -u root -p $MYSQL_ROOT_PASSWORD << EOF
source /var/lib/mysql/backup.sql
EOF
EOF

# MySQL 컨테이너 중지
echo "Stopping MySQL container..."
docker stop $MYSQL_CONTAINER_NAME

# MySQL 이미지 삭제
echo "Deleting MySQL image..."
docker rmi $MYSQL_IMAGE_NAME

echo "***** restore_data.sh Ended *****"
