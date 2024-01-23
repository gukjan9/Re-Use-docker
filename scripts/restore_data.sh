echo "***** Executing restore_data.sh *****"

# .env 파일 로드
echo "Loading .env... [1/8]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# Docker 볼륨 생성
echo "Creating Docker volume... [2/8]"
docker volume create ${MYSQL_DATA}

# MySQL pull
echo "Pulling MySQL image... [3/8]"
# docker pull mysql
# (pi)
docker pull mysql --platform linux/x86_64

# restore 용 MySQL 환경변수 재설정
MYSQL_IMAGE_NAME="mysql:latest"
MYSQL_ROOT_PASSWORD="1234"
MYSQL_CONTAINER_NAME="restore_container"

# MySQL 실행
echo "Running MySQL container... [4/8]"
docker run --name $MYSQL_CONTAINER_NAME -v $MYSQL_DATA_PATH:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -d $MYSQL_IMAGE_NAME

# 백업 파일 복사
echo "Copying backup file to the container... [5/8]"
docker cp /home/$TARGET_SERVER_USERNAME/backup/backup.sql $MYSQL_CONTAINER_NAME:/var/lib/mysql/backup.sql

# MySQL에 접속하여 백업 데이터 복원
echo "Restoring data from backup... [6/8]"
docker exec -i $MYSQL_CONTAINER_NAME /bin/bash -c "mysql -u root -p$MYSQL_ROOT_PASSWORD < /var/lib/mysql/backup.sql"

# MySQL 컨테이너 중지
echo "Stopping MySQL container... [7/8]"
docker stop $MYSQL_CONTAINER_NAME

# MySQL 이미지 삭제
echo "Deleting MySQL image... [8/8]"
docker rmi $MYSQL_IMAGE_NAME

echo "***** restore_data.sh Ended *****"
